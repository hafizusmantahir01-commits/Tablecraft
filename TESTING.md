# Tablecraft test checklist

Run `flutter test` first (10 unit tests must pass). Then test by hand on a real Android phone, and on web.

## Navigation (system back button / back gesture)

| Start screen | Action | Expected |
|---|---|---|
| Splash | Wait | Main screen (Levels tab) after about 2 seconds |
| Levels tab | Back | App closes (never back to the splash) |
| Daily, Create or Me tab | Back | Levels tab |
| Easy / Medium / Hard sheet | Back | Sheet closes, level not started |
| Game | Back (or top-left arrow) | The tab you came from, with a "Continue" card on Levels |
| Level complete | Back or "Back to levels" | Levels tab, next level open |
| Level complete | "Next: level N", then Back | Levels tab |
| Settings / How to play / About / Achievements / Privacy | Back | Me tab (Privacy from About goes back to About) |
| Table background | Back | Settings, old background kept |
| Any dialog | Back | Dialog closes, nothing changes |

## Levels
- [ ] Every level shows a different picture (fields, lake, city, castle, space ...), never the same scene twice in a row
- [ ] Fresh install: only level 1 open; tapping a locked level shows "Finish level N first"
- [ ] Tapping an open level asks Easy / Medium / Hard, with the piece count for each
- [ ] Level 1: Easy 4, Medium 9, Hard 16 pieces. Level 50: Easy 36, Medium 64, Hard 100
- [ ] Hard: pieces start turned (tap to turn)
- [ ] The last choice is pre-selected next time; "Next: level N" uses the same mode
- [ ] Finish level 1: level 2 opens, level 1 shows stars; replaying keeps the best stars
- [ ] Unfinished level tapped again: continues directly (no mode question)

## Daily (week 1 starts on the install day)
- [ ] Fresh install: "Week 1" starts today; today is the first box, the next 6 days are locked
- [ ] Tapping a locked day shows "This puzzle opens on ..."
- [ ] After 7 days "Week 2" starts
- [ ] Solving a day: tick on that day, streak goes up, the dot on the Daily tab disappears
- [ ] Solving all 7 days: "Perfect week! +100 bonus coins" (only once per week)
- [ ] Reset all game data: Week 1 starts again from that day

## Create
- [ ] Create tab: example picture, "Choose from gallery" and (on phones) "Take a photo"
- [ ] Gallery: pick photo, choose size, play. Camera: take photo, choose size, play
- [ ] Cancel the picker or the camera: nothing happens

## Sound, vibration, celebration
- [ ] Phone media volume up: lifting a piece ticks, a fitting piece clicks, a hint chimes
- [ ] A fitting piece also gives a short buzz (Android: even if "vibrate on touch" is off in phone settings)
- [ ] Finishing a puzzle: "Congratulations!" pops in, confetti falls, win music plays, a longer buzz
- [ ] Buttons under the confetti can still be tapped
- [ ] Settings > Sound effects off: silent. Settings > Vibration off: no buzz

## Me
- [ ] Change photo (pick / remove) and name; Levels tab greets you by name
- [ ] Stats and achievements update after finishing puzzles
- [ ] A new achievement appears once on the complete screen, then is coloured in Achievements
- [ ] Contact us opens the email app straight away, with our address and a subject filled in
- [ ] Privacy policy > Email us does the same
- [ ] About Tablecraft: app info, features, developer, Contact us, Open source licenses (no privacy page inside)
- [ ] Settings: vibration off = no buzz when a piece snaps
- [ ] Settings: Reset all game data -> back to level 1, 100 coins, name "Player"

## Gameplay
- [ ] Drag a piece to its spot: it snaps, phone vibrates, counter goes up
- [ ] Wrong spot or outside the board: piece goes back to the tray
- [ ] Swipe the tray sideways: it scrolls, does not pick a piece
- [ ] Edges, eye (picture under board) and timer work
- [ ] After 3 hints: "Buy" offer for 20 coins; with fewer than 20 coins a message instead
- [ ] Rotate on (own photo puzzles): tap to turn; a turned piece in the right spot shows the "turn it upright" message

## Saving
- [ ] Leave a level half done, close the app fully, reopen: Continue card, same pieces, same time
- [ ] Start a different puzzle while one is saved: you are asked first
- [ ] Tap the same unfinished level again: it continues instead of restarting

## Screens and devices
- [ ] Splash: logo spins in, no white flash before it
- [ ] Small phone (5 inch) and large phone: nothing cut off
- [ ] Web in a wide window: app centred, mouse drag and tray scrolling work
- [ ] App icon and name "Tablecraft" correct on the home screen
