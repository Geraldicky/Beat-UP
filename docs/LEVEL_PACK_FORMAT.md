# `.beatup-pack` format v1

A Beat UP! level pack is a ZIP archive with a `.beatup-pack` extension. Paths
are relative, use `/`, and may not be absolute or contain `..` segments.

Required layout:

```text
manifest.json
charts/normal.json
```

Optional entries are `charts/hard.json`, `charts/master.json`, one audio file,
and one background image. Supported audio extensions are OGG, MP3, and WAV;
supported artwork extensions are PNG, JPG/JPEG, and WebP.

Minimal manifest:

```json
{
  "format": "beatup-level-pack",
  "format_version": 1,
  "song": {
    "id": "my_song",
    "title": "My Song",
    "artist": "Artist"
  },
  "charts": ["charts/normal.json"],
  "audio": "audio.ogg",
  "background": "background.webp"
}
```

Importer limits are 512 MB per archive, 384 MB for audio, 24 MB for artwork,
8 MB per chart or manifest, and 16 archive entries. Charts are structurally
validated before any installation begins. New installs are staged in a private
temporary directory and renamed into place only after all files are written.
Duplicate archive entries, duplicate difficulties, unsafe paths, unknown
difficulties, and implicit overwrite attempts are rejected.
