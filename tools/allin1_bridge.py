#!/usr/bin/env python3
"""Stable bridge between Godot's Chart Editor and all-in-one-infer.

v14.2 bulk behavior:
- Uses AllInOneSession when the installed all-in-one-infer exposes it.
- Keeps one Harmonix + separation pipeline resident while processing a chunk.
- Processes tracks one by one so Godot receives real per-track progress.
- Writes a small progress sidecar with a one-second heartbeat while inference is alive.
- Falls back to the legacy multi-path analyze() API on older package versions.
- Normalizes the selected FLAC analysis source to a temporary PCM16 WAV (legacy OGG/WAV decoding remains supported internally).
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import traceback
import wave
from pathlib import Path
from typing import Any, Optional


@contextmanager
def _quiet_inference_output():
    """Give progress-bar libraries a valid sink when Godot has no console.

    On Windows ``tqdm`` may flush the inherited/captured stdout handle from a
    background Godot process and raise ``OSError(22)``.  All useful progress is
    already written through ``ProgressReporter``, so third-party terminal output
    is deliberately redirected while the model is running.
    """
    previous_stdout = sys.stdout
    previous_stderr = sys.stderr
    with open(os.devnull, "w", encoding="utf-8") as sink:
        try:
            sys.stdout = sink
            sys.stderr = sink
            yield
        finally:
            sys.stdout = previous_stdout
            sys.stderr = previous_stderr


class ProgressReporter:
    def __init__(self, path: Optional[str]) -> None:
        self.path = Path(path).expanduser().resolve() if path else None
        self.started = time.monotonic()
        self._lock = threading.RLock()
        self._stop = threading.Event()
        self._state: dict[str, Any] = {
            "alive": True,
            "phase": "STARTING",
            "detail": "Starting Python bridge",
            "current": 0,
            "total": 0,
            "song_id": "",
            "device": "",
            "model": "",
            "elapsed_seconds": 0,
        }
        self._thread: Optional[threading.Thread] = None

    def start(self) -> None:
        if self.path is None:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._write()
        self._thread = threading.Thread(target=self._heartbeat, daemon=True)
        self._thread.start()

    def update(self, phase: str, detail: str = "", **values: Any) -> None:
        if self.path is None:
            return
        with self._lock:
            self._state["phase"] = phase
            if detail:
                self._state["detail"] = detail
            for key, value in values.items():
                self._state[key] = value
        self._write()

    def finish(self, phase: str = "DONE", detail: str = "Finished") -> None:
        if self.path is None:
            return
        with self._lock:
            self._state["alive"] = False
            self._state["phase"] = phase
            self._state["detail"] = detail
            self._state["elapsed_seconds"] = int(time.monotonic() - self.started)
        self._write()
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=1.5)

    def _heartbeat(self) -> None:
        while not self._stop.wait(1.0):
            with self._lock:
                self._state["elapsed_seconds"] = int(time.monotonic() - self.started)
            self._write()

    def _write(self) -> None:
        if self.path is None:
            return
        try:
            with self._lock:
                payload = dict(self._state)
                payload["elapsed_seconds"] = int(time.monotonic() - self.started)
            temp = self.path.with_suffix(self.path.suffix + ".tmp")
            temp.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
            temp.replace(self.path)
        except Exception:
            # Progress telemetry must never fail the actual music analysis.
            pass


def _write_json(path: Optional[str], payload: dict[str, Any]) -> None:
    text = json.dumps(payload, ensure_ascii=False, indent=2)
    if path:
        target = Path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
    else:
        print(text)


@contextmanager
def _analysis_workspace(output: str):
    """Keep All-In-One spectrogram/stem byproducts out of the Godot project."""
    output_parent = Path(output).expanduser().resolve().parent
    output_parent.mkdir(parents=True, exist_ok=True)
    previous_cwd = Path.cwd()
    with tempfile.TemporaryDirectory(prefix="beat_up_analysis_", dir=output_parent) as temporary:
        os.chdir(temporary)
        try:
            yield
        finally:
            os.chdir(previous_cwd)


def _load_pcm_wav_without_torchcodec(
    path: str,
    frame_offset: int = 0,
    num_frames: int = -1,
    normalize: bool = True,
    channels_first: bool = True,
) -> tuple[Any, int]:
    """Return a Torch tensor from PCM WAV using only wave + NumPy."""
    import numpy as np
    import torch

    with wave.open(str(path), "rb") as wav:
        channels = wav.getnchannels()
        sample_rate = wav.getframerate()
        sample_width = wav.getsampwidth()
        if sample_width != 2:
            raise RuntimeError(f"PCM fallback expects 16-bit WAV, got {sample_width * 8}-bit")
        safe_offset = max(0, int(frame_offset))
        wav.setpos(min(safe_offset, wav.getnframes()))
        available = max(0, wav.getnframes() - wav.tell())
        requested = available if int(num_frames) < 0 else min(available, int(num_frames))
        raw = wav.readframes(requested)
    samples = np.frombuffer(raw, dtype="<i2").reshape(-1, channels)
    if normalize:
        samples = samples.astype(np.float32) / 32768.0
    tensor = torch.from_numpy(samples.copy())
    if channels_first:
        tensor = tensor.transpose(0, 1).contiguous()
    return tensor, sample_rate


def _install_torchaudio_pcm_fallback() -> None:
    """Patch torchaudio.load only when its TorchCodec route is unavailable."""
    try:
        import torchaudio
    except Exception:
        return
    if getattr(torchaudio.load, "_beat_up_pcm_fallback", False):
        return
    original_load = torchaudio.load

    def compatible_load(
        uri: Any,
        frame_offset: int = 0,
        num_frames: int = -1,
        normalize: bool = True,
        channels_first: bool = True,
        format: Optional[str] = None,
        buffer_size: int = 4096,
        backend: Optional[str] = None,
    ) -> tuple[Any, int]:
        del buffer_size, backend
        try:
            return original_load(
                uri,
                frame_offset=frame_offset,
                num_frames=num_frames,
                normalize=normalize,
                channels_first=channels_first,
                format=format,
            )
        except Exception as exc:
            message = str(exc).lower()
            path = str(uri)
            if "torchcodec" not in message or Path(path).suffix.lower() != ".wav":
                raise
            return _load_pcm_wav_without_torchcodec(
                path,
                frame_offset=frame_offset,
                num_frames=num_frames,
                normalize=normalize,
                channels_first=channels_first,
            )

    compatible_load._beat_up_pcm_fallback = True  # type: ignore[attr-defined]
    torchaudio.load = compatible_load


def _package_info() -> tuple[Any, str]:
    _install_torchaudio_pcm_fallback()
    import allin1_infer

    return allin1_infer, str(getattr(allin1_infer, "__version__", "unknown"))


def _probe(output: Optional[str]) -> int:
    try:
        module, version = _package_info()
        payload = {
            "ok": True,
            "backend": "all-in-one-infer",
            "version": version,
            "python": sys.version.split()[0],
            "module": getattr(module, "__name__", "allin1_infer"),
            "session_api": bool(getattr(module, "AllInOneSession", None)),
        }
        _write_json(output, payload)
        return 0
    except Exception as exc:
        payload = {
            "ok": False,
            "backend": "all-in-one-infer",
            "error": f"{type(exc).__name__}: {exc}",
            "python": sys.version.split()[0],
            "install": "python -m pip install -U all-in-one-infer",
        }
        _write_json(output, payload)
        return 10


def _probe_audio(output: Optional[str]) -> int:
    soundfile_ready = False
    soundfile_error = ""
    try:
        import soundfile as sf

        soundfile_ready = "VORBIS" in sf.available_subtypes("OGG")
        if not soundfile_ready:
            soundfile_error = "libsndfile has no OGG/VORBIS encoder"
    except Exception as exc:
        soundfile_error = f"{type(exc).__name__}: {exc}"
    ffmpeg_ready = shutil.which("ffmpeg") is not None
    payload = {
        "ok": soundfile_ready or ffmpeg_ready,
        "soundfile": soundfile_ready,
        "ffmpeg": ffmpeg_ready,
        "error": "" if soundfile_ready or ffmpeg_ready else soundfile_error or "No Ogg Vorbis encoder found",
    }
    _write_json(output, payload)
    return 0 if payload["ok"] else 11


def _decode_wav(audio_path: str, output_path: str) -> int:
    source = Path(audio_path).expanduser().resolve()
    target = Path(output_path).expanduser().resolve()
    if not source.is_file():
        print(f"Audio file not found: {source}")
        return 21
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        # soundfile is a dependency of the analysis stack and writes a plain
        # PCM_16 WAV that Godot's deterministic local analyzer can read.
        import soundfile as sf

        samples, sample_rate = sf.read(str(source), dtype="float32", always_2d=True)
        sf.write(str(target), samples, sample_rate, format="WAV", subtype="PCM_16")
        return 0
    except Exception as soundfile_error:
        # Do not call torchaudio here: recent versions route every load
        # through optional TorchCodec, which is exactly the dependency this
        # bridge is designed to avoid. FFmpeg is the last dependency-free
        # fallback when soundfile is not available.
        ffmpeg = shutil.which("ffmpeg")
        if ffmpeg:
            process = subprocess.run(
                [ffmpeg, "-v", "error", "-y", "-i", str(source), "-c:a", "pcm_s16le", str(target)],
                capture_output=True,
                text=True,
                check=False,
            )
            if process.returncode == 0 and target.is_file():
                return 0
            ffmpeg_error = process.stderr.strip() or f"exit {process.returncode}"
        else:
            ffmpeg_error = "ffmpeg executable not found"
        print(
            "Could not normalize audio to PCM WAV. "
            f"soundfile: {soundfile_error}; ffmpeg: {ffmpeg_error}. "
            "Run tools/install_allin1_windows.bat to install soundfile."
        )
        return 22


def _transcode_vorbis(audio_path: str, output_path: str) -> int:
    """Normalize any readable OGG codec to Godot-compatible Ogg Vorbis."""
    source = Path(audio_path).expanduser().resolve()
    target = Path(output_path).expanduser().resolve()
    if not source.is_file():
        print(f"Audio file not found: {source}")
        return 23
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        import soundfile as sf

        samples, sample_rate = sf.read(str(source), dtype="float32", always_2d=True)
        sf.write(str(target), samples, sample_rate, format="OGG", subtype="VORBIS")
        if target.is_file() and target.stat().st_size > 0:
            return 0
        raise RuntimeError("soundfile produced no OGG output")
    except Exception as soundfile_error:
        ffmpeg = shutil.which("ffmpeg")
        if ffmpeg:
            process = subprocess.run(
                [
                    ffmpeg,
                    "-v",
                    "error",
                    "-y",
                    "-i",
                    str(source),
                    "-vn",
                    "-c:a",
                    "libvorbis",
                    "-q:a",
                    "5",
                    str(target),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            if process.returncode == 0 and target.is_file() and target.stat().st_size > 0:
                return 0
            ffmpeg_error = process.stderr.strip() or f"exit {process.returncode}"
        else:
            ffmpeg_error = "ffmpeg executable not found"
        print(
            "Could not convert the imported OGG to Vorbis. "
            f"soundfile: {soundfile_error}; ffmpeg: {ffmpeg_error}. "
            "Run tools/install_allin1_windows.bat, then import the song again."
        )
        return 24


def _segment_payload(segment: Any) -> dict[str, Any]:
    return {
        "start": float(getattr(segment, "start", 0.0)),
        "end": float(getattr(segment, "end", 0.0)),
        "label": str(getattr(segment, "label", "unknown")),
    }


def _resolve_device(requested: str) -> str:
    value = (requested or "auto").strip().lower()
    if value not in {"", "auto", "default", "none"}:
        return value
    try:
        import torch

        if torch.cuda.is_available():
            return "cuda"
        mps = getattr(getattr(torch, "backends", None), "mps", None)
        if mps is not None and mps.is_available():
            return "mps"
    except Exception:
        pass
    return "cpu"


def _analysis_payload(
    result: Any,
    *,
    version: str,
    model: str,
    resolved_device: str,
    requested_device: str,
) -> dict[str, Any]:
    return {
        "ok": True,
        "backend": "all-in-one-infer",
        "version": version,
        "model": model,
        "device": resolved_device,
        "requested_device": requested_device,
        "path": str(Path(str(getattr(result, "path", ""))).expanduser().resolve()),
        "bpm": float(getattr(result, "bpm", 0.0)),
        "beats": [float(v) for v in getattr(result, "beats", [])],
        "downbeats": [float(v) for v in getattr(result, "downbeats", [])],
        "beat_positions": [int(v) for v in getattr(result, "beat_positions", [])],
        "segments": [_segment_payload(v) for v in getattr(result, "segments", [])],
    }


def _first_result(result: Any) -> Any:
    if isinstance(result, list):
        if not result:
            raise RuntimeError("All-In-One returned an empty result list")
        return result[0]
    return result


def _analyze(audio_path: str, output: str, device: str, model: str, progress: Optional[str]) -> int:
    reporter = ProgressReporter(progress)
    reporter.start()
    audio = Path(audio_path).expanduser().resolve()
    if not audio.exists():
        reporter.finish("ERROR", "Audio file not found")
        _write_json(output, {"ok": False, "error": f"Audio file not found: {audio}"})
        return 11

    try:
        reporter.update("IMPORT BACKEND", "Importing all-in-one-infer")
        allin1_infer, version = _package_info()
        resolved_device = _resolve_device(device)
        reporter.update(
            "MODEL + INFERENCE",
            audio.name,
            current=1,
            total=1,
            song_id=audio.stem,
            device=resolved_device,
            model=model,
        )
        with _quiet_inference_output():
            result = _first_result(allin1_infer.analyze(str(audio), model=model, device=resolved_device))
        reporter.update("NORMALIZE", audio.name, current=1, total=1)
        payload = _analysis_payload(
            result,
            version=version,
            model=model,
            resolved_device=resolved_device,
            requested_device=device,
        )
        _write_json(output, payload)
        reporter.finish("DONE", audio.name)
        return 0
    except Exception as exc:
        reporter.finish("ERROR", f"{type(exc).__name__}: {exc}")
        payload = {
            "ok": False,
            "backend": "all-in-one-infer",
            "error": f"{type(exc).__name__}: {exc}",
            "traceback": traceback.format_exc(limit=8),
        }
        _write_json(output, payload)
        return 12


def _load_manifest(path: str) -> list[dict[str, Any]]:
    parsed = json.loads(Path(path).read_text(encoding="utf-8"))
    if isinstance(parsed, dict):
        parsed = parsed.get("items", [])
    if not isinstance(parsed, list):
        raise ValueError("Batch manifest must contain an items array")
    items: list[dict[str, Any]] = []
    for raw in parsed:
        if not isinstance(raw, dict):
            continue
        song_id = str(raw.get("song_id", "")).strip()
        source = Path(str(raw.get("path", ""))).expanduser().resolve()
        if not song_id:
            raise ValueError("Batch item is missing song_id")
        if not source.is_file():
            raise FileNotFoundError(f"Audio file not found for {song_id}: {source}")
        items.append({"song_id": song_id, "path": str(source)})
    if not items:
        raise ValueError("Batch manifest contains no valid items")
    return items


def _analyze_batch_with_session(
    items: list[dict[str, Any]],
    allin1_infer: Any,
    version: str,
    resolved_device: str,
    requested_device: str,
    model: str,
    reporter: ProgressReporter,
) -> list[dict[str, Any]]:
    session_cls = getattr(allin1_infer, "AllInOneSession", None)
    if session_cls is None:
        raise AttributeError("AllInOneSession is unavailable")

    reporter.update(
        "LOAD MODEL",
        "Preparing reusable All-In-One session",
        current=0,
        total=len(items),
        device=resolved_device,
        model=model,
    )
    session = session_cls(model=model, device=resolved_device)
    try:
        # Explicit load gives the UI a truthful model-loading phase. The source
        # separator remains lazy until the first mixed-input inference.
        load_method = getattr(session, "load", None)
        if callable(load_method):
            with _quiet_inference_output():
                load_method()
        normalized: list[dict[str, Any]] = []
        for index, item in enumerate(items, start=1):
            song_id = item["song_id"]
            path = item["path"]
            reporter.update(
                "ANALYZE TRACK",
                Path(path).name,
                current=index,
                total=len(items),
                song_id=song_id,
                device=resolved_device,
                model=model,
            )
            try:
                with _quiet_inference_output():
                    result = _first_result(session.infer(path))
                analysis = _analysis_payload(
                    result,
                    version=version,
                    model=model,
                    resolved_device=resolved_device,
                    requested_device=requested_device,
                )
                normalized.append({
                    "song_id": song_id,
                    "path": path,
                    "ok": True,
                    "analysis": analysis,
                })
                reporter.update(
                    "TRACK COMPLETE",
                    Path(path).name,
                    current=index,
                    total=len(items),
                    song_id=song_id,
                )
            except Exception as exc:
                # A single corrupt/problematic song does not invalidate a batch.
                normalized.append({
                    "song_id": song_id,
                    "path": path,
                    "ok": False,
                    "error": f"{type(exc).__name__}: {exc}",
                })
                reporter.update(
                    "TRACK FAILED",
                    f"{Path(path).name}: {type(exc).__name__}",
                    current=index,
                    total=len(items),
                    song_id=song_id,
                )
        return normalized
    finally:
        close_method = getattr(session, "close", None)
        if callable(close_method):
            close_method()
        else:
            release_method = getattr(session, "release", None)
            if callable(release_method):
                release_method()


def _analyze_batch_legacy(
    items: list[dict[str, Any]],
    allin1_infer: Any,
    version: str,
    resolved_device: str,
    requested_device: str,
    model: str,
    reporter: ProgressReporter,
) -> list[dict[str, Any]]:
    reporter.update(
        "LEGACY BATCH INFERENCE",
        f"{len(items)} tracks (upgrade all-in-one-infer for per-track session progress)",
        current=0,
        total=len(items),
        device=resolved_device,
        model=model,
    )
    paths = [item["path"] for item in items]
    with _quiet_inference_output():
        results = allin1_infer.analyze(paths, model=model, device=resolved_device)
    if not isinstance(results, list):
        results = [results]

    by_path: dict[str, Any] = {}
    for result in results:
        result_path = Path(str(getattr(result, "path", ""))).expanduser().resolve()
        by_path[str(result_path)] = result

    normalized: list[dict[str, Any]] = []
    for index, item in enumerate(items, start=1):
        result = by_path.get(str(Path(item["path"]).resolve()))
        if result is None:
            normalized.append({
                "song_id": item["song_id"],
                "path": item["path"],
                "ok": False,
                "error": "All-In-One returned no result for this track.",
            })
        else:
            analysis = _analysis_payload(
                result,
                version=version,
                model=model,
                resolved_device=resolved_device,
                requested_device=requested_device,
            )
            normalized.append({
                "song_id": item["song_id"],
                "path": item["path"],
                "ok": True,
                "analysis": analysis,
            })
        reporter.update("NORMALIZE", Path(item["path"]).name, current=index, total=len(items), song_id=item["song_id"])
    return normalized


def _analyze_batch(manifest_path: str, output: str, device: str, model: str, progress: Optional[str]) -> int:
    reporter = ProgressReporter(progress)
    reporter.start()
    try:
        items = _load_manifest(manifest_path)
        reporter.update("IMPORT BACKEND", "Importing all-in-one-infer", current=0, total=len(items))
        allin1_infer, version = _package_info()
        resolved_device = _resolve_device(device)
        session_api = bool(getattr(allin1_infer, "AllInOneSession", None))

        if session_api:
            normalized = _analyze_batch_with_session(
                items,
                allin1_infer,
                version,
                resolved_device,
                device,
                model,
                reporter,
            )
            execution_mode = "reusable_session"
        else:
            normalized = _analyze_batch_legacy(
                items,
                allin1_infer,
                version,
                resolved_device,
                device,
                model,
                reporter,
            )
            execution_mode = "legacy_batch"

        payload = {
            "ok": True,
            "backend": "all-in-one-infer",
            "version": version,
            "model": model,
            "device": resolved_device,
            "execution_mode": execution_mode,
            "count": len(normalized),
            "results": normalized,
        }
        _write_json(output, payload)
        success_count = sum(1 for item in normalized if item.get("ok"))
        reporter.finish("DONE", f"{success_count}/{len(normalized)} tracks analyzed")
        return 0
    except Exception as exc:
        reporter.finish("ERROR", f"{type(exc).__name__}: {exc}")
        payload = {
            "ok": False,
            "backend": "all-in-one-infer",
            "error": f"{type(exc).__name__}: {exc}",
            "traceback": traceback.format_exc(limit=12),
        }
        _write_json(output, payload)
        return 13


def main() -> int:
    parser = argparse.ArgumentParser(description="Godot bridge for all-in-one-infer")
    parser.add_argument("--probe", action="store_true", help="check whether all-in-one-infer is importable")
    parser.add_argument("--probe-audio", action="store_true", help="check whether Ogg Vorbis conversion is available")
    parser.add_argument("--analyze", metavar="AUDIO", help="analyze one audio file")
    parser.add_argument("--analyze-batch", metavar="MANIFEST", help="analyze many audio files from a JSON manifest")
    parser.add_argument("--decode-wav", metavar="AUDIO", help="decode audio to a PCM WAV for local analysis")
    parser.add_argument("--wav-output", help="PCM WAV output path used with --decode-wav")
    parser.add_argument("--transcode-vorbis", metavar="AUDIO", help="convert an OGG source to Godot-compatible Ogg Vorbis")
    parser.add_argument("--ogg-output", help="Ogg Vorbis output path used with --transcode-vorbis")
    parser.add_argument("--output", help="output JSON path")
    parser.add_argument("--progress", help="optional live progress JSON sidecar path")
    parser.add_argument("--device", default="auto", help="auto, cpu, cuda, cuda:N, or mps")
    parser.add_argument("--model", default="harmonix-all", help="All-In-One model name")
    args = parser.parse_args()

    if args.probe:
        return _probe(args.output)
    if args.probe_audio:
        return _probe_audio(args.output)
    if args.analyze:
        if not args.output:
            parser.error("--output is required with --analyze")
        with _analysis_workspace(args.output):
            return _analyze(args.analyze, args.output, args.device, args.model, args.progress)
    if args.analyze_batch:
        if not args.output:
            parser.error("--output is required with --analyze-batch")
        with _analysis_workspace(args.output):
            return _analyze_batch(args.analyze_batch, args.output, args.device, args.model, args.progress)
    if args.decode_wav:
        if not args.wav_output:
            parser.error("--wav-output is required with --decode-wav")
        return _decode_wav(args.decode_wav, args.wav_output)
    if args.transcode_vorbis:
        if not args.ogg_output:
            parser.error("--ogg-output is required with --transcode-vorbis")
        return _transcode_vorbis(args.transcode_vorbis, args.ogg_output)
    parser.error("use --probe, --analyze AUDIO, --analyze-batch MANIFEST, --decode-wav AUDIO, or --transcode-vorbis AUDIO")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
