# Practice removal / Song Library Note Speed

The Song Library secondary action is now NOTE SPEED. It opens a reusable modal
with the actual diamond-note renderer, a reading-time slider, presets, and a
140/220 BPM comparison. Changes use UserSettings' existing canonical preference
and apply to the next run; opening the preview does not launch gameplay or alter
the selected song. Suspension hides the modal and closing restores button focus.

Removed the Practice section selector, launch signal/handlers, section filtering,
loop playback, Practice record writer/export, and tutorial training phrase/tab.
The three-page controls/timing/specials guide remains. Stale requests containing
practice_section_index are explicitly rejected rather than converted into scored
full-song runs. Existing user://practice_records.json is never deleted or migrated.
Chart Studio chart sections and authored chart files remain untouched.

Regression coverage lives in song_library_rhythm_redesign_test.gd and
note_readability_test.gd. The layout capture harness no longer invokes retired
Practice methods. Application version remains 18.7.0.1.
