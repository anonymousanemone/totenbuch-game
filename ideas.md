
# Totenbuch Game: Vignette Catalogue & Puzzle Ideas

Base scroll: Lepsius, *Das Todtenbuch der Ägypter* (1842), the Turin papyrus of Iufankh. Spell numbers follow Lepsius (1–165).
Legend: **[seen]** = checked against the plates in the PDF. **[verify]** = a detail I'm not sure of. Plate numbers (pl. I–LXXIX) are Lepsius's Roman numerals at the top corner of each page.

Design rule throughout: **the end is the Weighing of the Heart (125d).** Every earlier scene should give the player an item, an ability, or a piece of *evidence* that gets used at the scale.

---

## What each level teaches (for continuity) (approved 2026-11-06)

**What counts as "taught":** a specific thing the player can recognise (a sign, a god's look or name, an object's shape) that is **first met with a clue at hand** in that level and could be **asked for again later** (further on in the same level, or in another level) without that clue, so the player has to remember it or look it up in the journal. It needn't be memorised; a journal entry that reminds the player of the earlier scene is enough.
- **Doesn't count:** general skills (timing, observation, asking figures, reading tells). These go into the level's **skill vs creativity** ratio instead (see the scale in `TODO.md`). Also out: things with no later use found yet, things the level only recalls, and the level's whole content.
- **Ratio:** skill = executing understood actions (timing, precision, practice, *memorisation*); creativity = discovering and interpreting (spotting, reading captions, working out what to do).
- **Recalls:** what a level asks back from an earlier one. Listed so the chain shows.

| Level | Skill / creativity | Why (brief) |
|---|---|---|
| Procession (1–16) | 25 / 75 | Only the haul and the pour are rhythm; the standards, table, goose, bulls, adze and stand are spotting and restoring. |
| Cosmos (17) | tbd | Walk-and-read only; its games aren't chosen. |
| Dangers (31–42) | 80 / 20 | Every vignette is a spear fight, but the captions decide the heka crocodiles (31), the Merti snakes (37) and breath vs life (38). |
| Survival (43–63) | 50 / 50 | Skill: steadying the mummy (45), covering and catching the loaves (52–53), the bend under the stream (57). Creativity: sceptres as lives, claiming the dwelling, flipping upright, finding the sails, the caption signs. |
| Ba, Thoth & boats (89–109) | 20 / 80 | Mostly animation and decisions (refuse at 93, offer at 94, board at 98); turning the boat at 100–102 is the one handling part. |
| Field of Reeds (110) | tbd | Only feed-the-gods is decided. |
| Gates (144–147) | 90 / 10 | Mostly a memorisation game: which name goes to which god. |

**Procession (1–16)**
- **Offering stand** (stand, sun disc, lotus bending over it). First: rebuilt before Ra, with the stela by the tomb as the clue. Later: 94/95's stand, the boats of 17, 110's and 147's stands, with no stela nearby.
- **Anubis and Ra**, what they look like (only these few gods here). First: Anubis holding the mummy, Ra enthroned. Later: 45 (Anubis holds the mummy again), 17, 117 (Anubis leads), 125 (Anubis at the scale).

**Cosmos (17)** (tentative, games not chosen)
- **Gods by head and name sign:** Isis (throne) and Nephthys (basket on house) as kites at the bier, the Four Sons by their heads. Later: the 18 councils, 148's four figures, 125's Four Sons.
- **The sun's cycle:** the east and west falcons, the two horizon lions, the morning and evening boats. Later: 93 (the east sign tells you to refuse the boat), 100–102 sailing west, 109's sycamores of the east. (The east sign may be taught at 16 instead, if that level is made.)
- **Canopic chest:** between the Four Sons, and carried in pl. X. Later: 151's burial chamber, 125's Four Sons.
- **Wedjat eye:** on its shrine. Later: 148's four oars, the two on the 125 cornice.

**Dangers (31–42)**
- **Breath (the sail sign).** First: 38, where the caption's title has "breath" in bold. Later: 54–62, the seven sails.
- **Life (the ankh).** First: 38, beside the sail. Later: 56's lowered hand, Isis in 17, the crest of 146's portal 2.

**Survival (43–63)**
- **Feather (*maa-kheru*, true of voice).** First: 48, the signs grow when clicked. Later: Ma'at's feather at the 125 scale.
- **Fire hieroglyph.** First: 63, the flame on a stand. Later: 126's lake of fire, 137's torches.
- **Was-sceptre.** First: 43, the three sceptres that become your lives. Later: gods holding it, e.g. 147's baboon gods.
- **Bread, water and breath, as a set.** First: the loaves (52–53), the tree goddess's water (57, 59), the sails. Later: 110 (feed the gods), 125 ("bread to the hungry, water to the thirsty").
- **Recalls:** the sail (38), Anubis holding the mummy (procession).

**Ba, Thoth & boats (89–109)**
- Teaches nothing new so far.
- **Recalls:** the east sign at 93 (Cosmos, or 16); at 94, that caption signs can be clicked and used (Survival), here the cup sign; the offering stand at 95 (procession).

**Field of Reeds (110)**
- **Grain from the two heaps.** First: carried from the middle register to the stands. Later: 148 (feeding the cows with food from 110).

**Gates (144–147)**
- **Which name goes to which god.** First: 145, where a wrong name zips off to its right god. Later: 146's matching portals (8/9 and 14/15 swap places), 147 ↔ 144 (4/5 swap).
- **Names as glyph shapes:** recognised by their look, no reading needed. Later: possibly naming the door at 125.

**Not listed yet:** 112–124, 126–143, 149–150 and the amulets (155–160) wait until their games are decided; 125 (what it recalls) waits until the finale design is chosen.

---

## How the player learns things (recap)
- **Cross-reference:** a figure seen correctly in one vignette is the answer in another.
- **Headgear/heads as identity:** teach the heads (jackal, ibis, falcon, baboon, ram, crocodile, lion, snake) early. The gates use them heavily.
- **Silhouette holes:** cropped figures leave gaps the colour of the papyrus.
- **Reactive art:** figures flip, nod, or turn away; flames flicker.
- **Journal:** clicking a figure saves a snapshot with its surroundings.

## Interface decisions (2026-10-14)
- **The Journal keeps clue notes.** When a figure that shows a problem is first clicked, its entry records what is wrong. Three rules:
  - The note says what is wrong, never how to fix it ("He holds a loaf, not his goose").
  - It looks exactly like any other entry: no icon, colour or sorting that marks it as a problem.
  - Once the problem is fixed, the note changes to describe the figure as drawn.
- **Hint becomes graded.** Each press says a little more: where to look, then what is wrong, then what to do. It picks the problem nearest the player, or one they have already noticed, not the first in a fixed order. This replaces today's single full-solution `hint()` in each level.
- **Progress shows in the scene.** Players need to know whether something is still wrong, without a counter. Examples: the procession not yet closed up, or the scribe saying the procession is in order.

---

## ACT I: Burial & Going Forth (1–18)

> Reading direction: the scroll reads **right to left**, so each strip "walks" leftward. Have the camera scroll that way too; it keeps the figures facing the direction of travel.

### 1–16: The funeral procession
One continuous strip across four plates, showing the living arriving in a funeral procession to his tomb. Includes the opening of the mouth, and adoration of Ra in the end. 

**In the game now** (`godot/README.md` has the details): whatever can be clicked glows; clicking a figure records it in the journal. Five tasks: haul the sledge, return the standards, rebuild the offering table, give the goose back, and set up the offering stand before Ra (spell 15, below); then you kneel before Ra and the level ends.

**Puzzles**
- **Procession order, done:** the standard-bearers are scrambled. Their standards (jackal, falcon, and so on) **match the gods you will meet later**, so restoring the order is your first lesson in god emblems. The correct order is copied into the journal.
  - *In the game:* the eight bearers (four in pl. III, four in pl. II) carry the wrong gods; Take a standard and set it on a pole; a filled pole swaps. An empty pole shows its own standard faintly. The lector with two plumes (pl. V) reads out the order: the eight signs appear one by one above his sheet. Copying the order into the journal is not in yet.
- **Haul the sledge (rhythm):** you become the hauler. The man in front with his arm raised calls the beat; press on the beat to lean into the rope. A miss lets the rope go slack and the bier stops. A possible second layer: the priest before the bier keeps the incense going (hold, release before it flares) while you haul.
  - *In the game:* nobody is on the rope at first; click the ox-driver, the censer priest or the sledge to take it up where the hauler is drawn. The vignette opens out over the start of pl. I and the train stands back from its place. The driver's whip (his forearm, swinging about the elbow) comes down on every beat, with a drum. Press on it and the train gains a step; off the beat the sledge slips back; a beat let pass and it stops. Twelve good pulls bring it home, and the drawn hauler appears on his rope. The incense layer is not in.
- **The three bulls, done (one mini-game):** step up to it and the camera pans out to hold all three at once: the plumed bull, the bound bull on the block, and the calf between them.
  - **The calf faces the sacrifice.** At the start it is turned towards the bull on the block, watching what is coming to it. Drag it and it flips about its own vertical centre line to face the plumed bull, with its back to the sacrifice, as drawn. Give feedback either way: it shies while it faces the block and settles once it is turned away. Don't make the poor calf watch its own future.
  - **The crown is on the wrong bull.** The disc and plumes sit on the bound bull on the block, and the plumed bull walks bare. There is no faint outline where they belong. Drag them onto the plumed bull. Cut the disc and plumes as their own layer; the horns stay. [verify] they come apart cleanly.
  - Either fix can come first. With both done, the plumed bull lowers its head to the calf and lows, and the camera pans back.
- **The offering table (pl. IV), done:** the heap has collapsed. Everything but a few pieces lies loose on the floor between the two pairs of tall bouquets (they look like plants bound to poles; the right pair has lotus wound round), at any angle. Stack it again like a jigsaw: a piece only snaps into place once what it rests on is there, otherwise it topples back down. The palm frond lies in the empty band above, a little to the right, and goes on last. The goose-bearer is holding a loaf from the heap instead of his goose; the goose lies among the fallen offerings. The lector beside the table shows one piece you can stack now, in front of him.
  - *In the game:* click the table (or a piece, the lector or the goose-bearer) to step up to it; the camera holds on the table, and Esc or walking off steps away without losing anything. The pieces are physics bodies with a faint papyrus fill. Press to take one up, and let go or click to set it down. It goes in near its place only once what it rests on is there (`rests_on`), else it topples. Pieces set down in the band above stay there, out of the way.
  - **Give the goose back, done:** take the loaf from the goose-bearer, then give him the goose. While his arms are empty, the clothes the goose and loaf cover show.

- **The offering stand before Ra (the ending), done:** the stand, the sun disc on it and the lotus over it are gone from before Ra, and the adorer kneeling before him is gone too. Once every other rite is done, the stela shows a faint imprint of the three as they stood; before that its face is blank. The stand can still be set up early, but the finale waits: clicking the finished stand or Ra says that some things have not been set right yet. They lie hidden along the scroll: the stand inside the canopy frame behind the women mourners (pl. I), the sun disc between the legs of the creature on the mummy's bier (pl. II, riding with the sledge), the lotus on top of the second offering pile (pl. V). Carry them to Ra and set them up, stand first (a piece with nothing to rest on won't go). Once that and the other rites are done, you walk to the adorer's place and kneel there; light pours from Ra's disc and the new sun and floods the screen, and the level ends (for now, back to the menu).
  - *Pieces:* `sprites` folder in the .mdp (`stand`, `sun`, `lotus`); the adorer is cut from p6 by the cutter (`kneeler`).
- **Pour the water, done:** the jar starts upright and there's no stream. Drag the jar to tilt it about the wrist; inside a tilt window the water runs along the drawn line and the line draws itself in. Too steep and the stream falls short and splashes on the woman; too shallow and it only drips. Out of the window, the drawn part dries back a little (never to nothing). Solved: the whole line closes round Anubis and the mummy, as drawn. Cues: a dotted ghost of the line, the jar glowing, the line only growing while held steady.
  - *Pieces:* the jar cut from the hand (small redraw of the fingers); the stream as its own `water` layer, with its path as a polyline.
  - *New:* a shader that reveals the stream along its length; holding a tilt as input (closest: the whip turning about the elbow, but held, not on a beat).
  - *In the game:* click the priest, the woman, Anubis and the mummy, or the jar to step up behind the priest; the camera holds on the scene. His forearm with the hand and jar turns about the elbow, not the wrist, so no redraw is needed: press on the jar and drag. Inside the window and held steady, the line inks in from the spout, with drops running along it. Swung about, it slops and doesn't grow. Shallow, it drips; steep, it gushes onto her raised hands. Out of the window it dries back to 60% of the furthest reached. Let go and the arm rises back upright. The arm and stream are cut from p5 by a stand-in until the .mdp has a `water` folder (`arm`, `stream`).
- **Cense, to do:** the censer priest (facing the stand) holds the arm-censer and a small cup of incense pellets. Flick pellets from the cup into the bowl at the end of the arm; each one that lands sends up a puff of smoke over the stand. Enough of them and the stand is censed. A timing game, unlike the water's steady hold.
  - *Pieces:* the arm-censer and the cup as layers. *New:* smoke particles.
- **Open the mouth (the adze):** the mummy's face is blank: no eye, no mouth line. The caption in front of it (above the woman and the jar priest) is empty too. The adze lies on the stand over the foreleg.
  - *Finish the face:* the mummy's face (eye, mouth line) is only a faint imprint. With the adze in hand, click the mummy and the camera closes in on its head. 
  - after the face is finished the words come out of its mouth as a ball that rises and unrolls into their line in the empty band above the mummy. Take the line and set it at its imprint over Ra. 
- Assemble the offering stand for ra: gather the lotus, stand, and rsun from around the strip and assemble at ra's feet. you can only take the objects after most tasks are done.
- **Stand the mummy up, tabled (a lead-in to Open the mouth):** the mummy lies flat on its base and Anubis has nothing to hold. Drag its head up: it turns heavily about its feet; let go early and it falls back. Hold it upright for a moment and Anubis's arm closes round it. Overshoot and it tips toward you; the woman covers her face.
  - *Pieces:* `mummy`, and `anubis_arm` turning at the shoulder; a little redrawing of hidden lines. [verify] the arm separates.
 

**Games still to think of** 
- **The barque.**
- **The mourning women.**
- **The two object carriers** right behind the Apis bull.
- **The incense:** the censer priest before the bier (see the incense layer idea under the rhythm haul).
- **The second offering table** (pl. V): maybe a game of its own.
- Research a drawing or 2D rigging tool that lets you select part of an image, set a pivot/reference point and rotate that part around it.

### 15: Arrival at the tomb (pl. V–VI, right) [seen]
### 16: The three-tier sun picture (pl. VI, left) [seen]
- **Depicts, top to bottom:**
  - **Ra's boat** with a crew of gods.
  - **(a)** a **sun disc pouring rays** down onto **two kneeling goddesses** facing each other, with sceptres at each side.
  - **(b)** a figure holding the **sun disc up** with **eight baboons adoring** in two rows, four on each side.
  - **(c)** the **deceased and wife seated**, receiving an offering from a standing man.
- **Puzzle:** **raise the sun.** Work from the bottom up: feed the couple, then get the baboons to adore (cue them by facing them all toward the disc), then lift the disc so the rays fall between the goddesses. Sunrise sets the **compass**: the rays mark the east. This is the game's first compass lesson and introduces baboons, who return at 126 and 125d.

### 17: The long cosmological strip (pl. VII–XI) [seen]
Five plates of continuous small scenes, reading right to left:
- **Pl. VII:**
  - a standing figure; the **deceased seated in a booth at a game table (senet)**
  - a **falcon on a perch**; the **ba** (a bearded, human-headed bird) on a low stand; two adoring figures
  - **Ra's boat with a crew of gods holding spears**
  - a **seated lion (Aker) with the horizon sign** at the far end
- **Pl. VIII:**
  - the **second lion** with the horizon; a **heron (Benu)**
  - the **mummy on a lion bier**, with vessels underneath and **Isis and Nephthys as kites** at its foot and head
  - **two kneeling women (Heh and Wadj-wer)**, each reaching a hand over a small pool
  - a **shrine with a rearing snake and three blades on its roof** (the gate of Rosetau); a seated figure
  - a **wedjat eye on a shrine**; a figure raising an arm
  - a **cow (Mehet-Weret) on a shrine**; a mummiform god
- **Pl. IX:**
  - a mummiform god; a **tall shrine with a god seated on top**
  - **mummiform figures with jackal and falcon heads** (some of the Four Sons); a figure with **two eyes above its head**
  - a **lotus/offering basin**; **two seated gods**
  - a **persea tree** with a **cat sitting at it**
  - a falcon on a standard; two crouching figures; the deceased adoring
  - a **boat carrying a god with tall horns**
- **Pl. X:**
  - pairs of **baboons adoring** on both sides of **Ra's boat**, with the sun-disc god seated in the middle
  - **Isis and Nephthys standing** (signs on their heads)
  - the deceased **carrying a chest/shrine on his head**
- **Pl. XI (end):**
  - a **large goddess bending over a scarab and a kneeling woman** (the sky/birth scene)
  - **Osiris enthroned**; an offering stand; the deceased adoring; a **jackal-headed god** standing

**Descriptions checked against Davis** (2026-10-22; Davis's 1894 ch. 17 text and vignette notes, plus the cut sprites)
- **Booth (pl. VII):** Davis: "the deceased standing up and walking, then sitting in front of an altar." The thing before him looks like the altar of loaves in spells 52–53, not a senet board. Senet ("playing at draughts") is only in the title. [verify] before building the senet game on it.
- **Ba (pl. VII):** Davis: "the human soul bearing around its neck the badge of stability and the hieroglyphic group indicating the Amenti." The barred object at the ba's front is the djed, and the falcon on its perch beside it is the West (Amenti) sign. This answers the "east/west" question below for pl. VII. The pl. IX falcon is drawn the same way, so its meaning there is still [verify].
- **Two adorers (pl. VII):** Davis: "the deceased is adoring a personage who holds on his arm a statue of Khem (Min) and who presents a lotus-flower." The raised object is a Min figure, not flowers, and the two men face each other, not the boat.
- **Mehet-weret:** Davis has the sun born "above the thigh of the cow Mehurit", not at her udders.
- **Heh and Wadj-wer:** Davis calls their pools "the basin of natron with the basin of nitre", then "the basin Maat". [verify] whether they are drawn as men or women.
- **The gate (pl. VIII):** Davis says "the gate through which passes the father Tmu to reach the eastern horizon" and does not use the name Rosetau. (Backes's translation of this papyrus does name Rosetau; see the Totenbuch-Projekt check below.)
- **Seven Glorious Ones:** Davis lists Amset, Hapi, Tiaumautef, Kebhsennouf, Maa-tef-f, Ker-bek-f and Har-Khent-an-merti (Horus Khenty-irty). Anubis set them to guard the sarcophagus of Osiris. The spirit with the curled sign should be Maa-tef-f or Ker-bek-f. [verify] which.
- **Isis and Nephthys:** Davis calls them "the two girls", the "justiciary guardians" by Khepri's bark. This loosely supports reading the two apes as them. [verify]
- Still unidentified: the crowned creature in the sun boat (VII), the two bowls (IX), the beaked figure by the tree (IX), the offerer before the cow (VIII; other copies have Thoth with the Eye), and whether the head on the chest (IX) is Ra's. Davis names only "the funeral chest containing the bowels of Osiris".
- [verify] Pl. XI (Osiris enthroned, Anubis, Nut over the lion and scarab, the kneeling pair): Davis's ch. 17 notes don't describe these. They may be the opening of ch. 18. The old Osiris quote ("My fair goal is with Osiris") couldn't be traced, so it was removed.
- [verify] The god in the evening boat wears a sun disc, which fits Ra better than Atum. The god in the morning boat has a horned head, not clearly a scarab.
**Checked against the Totenbuch-Projekt** (2026-11-06; https://totenbuch.awk.nrw.de/spruch/17, accessed 2026-11-06: Backes's translation of this papyrus, TM 57201, and the database's list of motifs in its spell 17 vignettes; cited as `TBP Spruch 17`)
- **Two apes:** Backes has the "reckoners" whom Khepri in his bark empowers as "the baboon, Isis and Nephthys". This supports reading the two apes as Isis and Nephthys more strongly than Davis's "two girls". Updated in the registry.
- **The gate:** the text names two gates in this passage: the Gate of the Desert (the gate of Shu's raising, where Atum passes to the eastern horizon) and Rasetjau (Rosetau). So Rosetau is in this papyrus too, not only in other copies. Which one is drawn: [verify]. Updated in the registry.
- **Name signs:** the motif list has kites, the Nephthys sign and the throne sign, which supports the name-sign readings for Isis and Nephthys. Added as their source.
- **Morning boat:** the motif list has a scarab-headed god, which fits the morning boat's god. [verify] against the crop.
- **Heh and Wadj-wer:** the motif list has a Nile god (Nilgottheit). If that is these two, they are drawn as Nile gods, which are male figures. [verify]
- **Leads, not answers:** the motif list also has a child, a canopic jar, a bag, a crescent moon, and the red and white crowns. These may help with the crowned creature in the sun boat and the two bowls. Backes calls the chest "the chest that holds the innards of Osiris", which Anubis stands behind; the head on it is still unidentified. The Seven Glorious Ones are listed by the same names as Davis, so which one the spirit with the curled sign is stays [verify].
- [verify] The three caption bands (`inscriptions_vii/viii/ix`) are given Davis's ch. 17 title, split across the three plates. The split points are a guess; the bands have not been read sign by sign.

**Scenes to make games for** (checked against the cut sprites, 2026-10-22)
- **Senet (pl. VII):** the deceased sits in an arched booth, staff in hand, facing a small table with the pieces standing on it. The deceased with his staff stands behind the booth. (`senet_booth`, `deceased_with_staff`)
- **The ba (pl. VII):** a human-headed, bearded bird on a low stand, beside the falcon on its perch. It is not beside the bier, as listed above. (`ba`)
- **The sun boat (pl. VII):** six gods stand in the boat, three on each side of a stand with a crowned creature under the sun disc. Each holds a long spear slanting down past the hull, all at the same angle. (`sun_boat_with_crew`)
- **The two lions (pl. VII):** they sit back to back, with the horizon (the disc between two hills) between them. (`lion_yesterday`, `horizon`, `lion_tomorrow`)
- **The funerary bier (pl. VIII):** the mummy lies on a lion bier with four tied vessels beneath it. Two kites face it, one at each end: Isis (throne sign) at the foot, Nephthys (basket on house) at the head. [verify] whether the curl at the mummy's head is a small ba. (`mummy_on_bier`, `isis_kite`, `nephthys_kite`)
- **Isis and Nephthys, recurring:** as kites at the bier (VIII), maybe as the two apes facing Khepri's boat (IX), as two standing pairs, one on each side of Atum's boat with hands raised and Isis holding the ankh (X), and kneeling with their signs on their heads beside Nut (XI). The two kneeling women in pl. VIII are Heh and Wadj-wer, not Isis and Nephthys. (`isis_kite`, `nephthys_kite`, `two_apes_isis_nephthys`, `isis_nephthys_standing_1/2`, `isis_nephthys_kneeling`)
- **The gate of Rosetau (pl. VIII):** a tall gate with a snake rearing inside and three blades on its roof. (`rosetau_gate`)
- **The canopic chest and four sons (pl. IX):** a tall chest with a head rising from its top, two sons on each side: Qebehsenuef (falcon) and Hapy (baboon) to the right, Imsety (human) and Duamutef (jackal) to the left. This could tie to the **chest bearer** at the end of pl. X, who carries a chest high on one hand. (`chest_with_head_of_ra`, `qebehsenuef`, `hapy`, `imsety`, `duamutef`, `chest_bearer`)
- **The seated pair and the two facing them (pl. IX):** the twin souls (Osiris and Ra) sit on thrones facing right. Two ribbed bowls with signs heaped on them stand between them and two standing gods who face them: one with a pair of eyes above his head (Horus Khenty-irty), one with a curled sign on his head. (`twin_souls`, `two_bowls`, `horus_khenty_irty`, `spirit_with_emblem`)
- **The tree, the cat and the snake (pl. IX):** the persea tree, a small seated figure beside it, and the great cat with a knife at the snake, which winds along the ground. (`ished_tree`, `small_seated_god`, `great_cat_and_apep`)
- **The falcon standards on the east and west signs:** the falcon on its perch (VII) and the falcon on a tall standard with a flail at its back (IX). [verify] which sign is east and which west. (`falcon_on_perch`, `falcon_on_standard`)
- **The two boats with baboons:** Khepri's morning boat (IX) has the kneeling deceased and two squatting apes before it. Atum's evening boat (X) has two pairs of baboons standing and praising on either side, and two seated baboons beyond. Each boat carries a stand with a lotus. (`khepri_boat`, `two_apes_isis_nephthys`, `deceased_kneeling`, `atum_evening_boat`, `baboons_praising_1/2`, `baboons_seated_x`)
- **The worship of Osiris (pl. XI):** Osiris enthroned, a tall stand with a loaf and lotus, the deceased adoring, Anubis behind him. The stand with lotus and sun recurs in both boats and in the procession's ending before Ra. (`osiris_enthroned`, `offering_stand`, `deceased_adoring`, `anubis`)
- **Theme for later, Nut, the scarab and the lion (pl. XI):** Nut bends over a recumbent lion and a scarab, the setting sun and the sun reborn. It echoes the two lions (VII) and the two boats (IX–X), so it could close the level's sun cycle. (`nut_over_scarab`)

**Game suggestions for these scenes** (2026-10-22, not yet reviewed)
- **Senet:** a short race with the drawn pieces against the empty side of the booth. *New:* a top-down board, and a way to throw, since no throw sticks are drawn (needs approval).
- **Ba:** it flies off its stand when you walk straight at it, and settles back only while you stand still with your back to it. *Reuses:* the "while the back is turned" timing window.
- **Sun boat:** the six spears point at random angles. Turn each about its hand until all slant the same way, as drawn, and the boat moves off. *Reuses:* rotating about a pivot.
- **Two lions:** they start facing each other with the sun sunk. Turn them back to back and the disc rises between the hills.
- **Bier:** the two kites wail in turn (head lift and a sound), and you answer the call pattern. *New:* call-and-response with sound.
- **Isis and Nephthys:** the kites at the bier are drawn complete and teach the two head signs. The later pairs have lost theirs; set each sign back on its outline.
- **Rosetau gate:** the snake sways inside the gate (tail shader). Pass through only while its head is down.
- **Canopic chest:** the chest is gone from between the four sons, because the bearer in pl. X carries it. Bring it back and the head rises out of it.
- **Seated pair:** the twin souls are one soul, so they should look alike. One has a part out of place (arm, beard, sceptre); fix it until the two match. *Reuses:* copies and mirrors.
- **Tree, cat, snake:** strike when the head is under the knife. If that game is already built elsewhere, a variant: the snake hides behind the trunk, and you can strike only while it is in the open.
- **Falcon standards:** each falcon sits on the other's sign. Swap them back.
- **Two boats:** Khepri and Atum sit in each other's boats. The baboons keep their paws down until each god is in his own boat.
- **Osiris:** one lotus is carried along, from Khepri's stand to Atum's to Osiris's. It is close to the procession's finale before Ra, so keep it to the hand-off rather than rebuilding a stand.

**Possible merges**
- **The sun's day:** lions and horizon (sunset), then the gate (going out east), Khepri's boat, Atum's boat, and finally Nut over the lion and scarab as the level's finale. The lotus relay rides along this path.
- **Canopic chain:** the chest bearer (X), the chest and four sons (IX), the four vessels under the bier (VIII).
- **Isis and Nephthys:** one sign game spread across all their appearances: kites, apes, the standing pairs, the kneeling pair.
- **Birds:** the ba, the two falcons, the Benu and the kites are all startled off their places, and each is coaxed back the same way. This would replace the separate ba and falcon games.
- **Senet and the lions:** winning senet opens the horizon (see the puzzle below).

**Puzzles**
- **Senet opens the horizon:** play (or reach a set position in) senet in the booth on pl. VII. Winning slides the two Aker lions apart (they sit at the joins of pl. VII and VIII) and the strip continues.
- **Reorder the strip:** the strip's panels arrive shuffled. Restoring them builds the **journal's god reference page**. Key facts the player learns:
  - **Baboons adore the sun** (used at 16, 126 and 125d).
- **The cat and the persea tree:** the cat sits at the tree. Bring a snake-crop (from 33) into this panel and the cat attacks it. This teaches the "creature vs. counter" logic used throughout Act II.
- **Carry the chest:** the deceased on pl. X carries a chest on his head. It can hold the **heart scarab** later (30), a nice diegetic inventory.

### 18a–18j (plus a closing scene): The councils (pl. XI–XIII) [seen]
- **Depicts:**
  - **Pl. XI:** three panels (**18a–c**).
  - **Pl. XII:** six panels (**18d–i**).
  - **Pl. XIII:** a **closing panel**: the deceased adoring at an offering stand before **Osiris enthroned with two goddesses** standing behind him.
  - In each of 18a–i, the deceased **kneels** with hands raised before **three or four standing gods**. The gods vary: one has a sun disc (Ra), crowned gods, a jackal-headed god, ibis-headed, falcon-headed, and plumed gods.
- **Puzzles:**
  - **Fill the council:** each panel has one god missing (a silhouette hole). Pick the right god from the journal, using the god emblems from the procession and head shapes from 17. Ten courts with the same mechanic, getting harder: later courts have two or three holes.
  - **Rehearsal for the Weighing:** each court you complete earns a **"vindicated" token**. Tokens **count at the final scale (125d)**.
  - **Closing scene:** bring all tokens to the Osiris panel on pl. XIII. This is a miniature of the finale, so players learn its layout early.

### 21–29: Mouth & heart spells (pl. XIV–XV) [seen]
- **Depicts:**
  - **21–22:** a standing figure **touching or offering at the deceased's face**, the deceased sometimes seated (*giving a mouth*).
  - **23:** two standing figures face to face (opening the mouth).
  - **24:** a similar pair.
  - **25:** two figures facing.
  - **26:** the deceased kneeling, holding a heart before a large standing human-headed figure.
  - **27:** the deceased kneeling before **four seated gods** (the *heart-snatchers*).
  - **28:** the deceased adoring a **heart/ankh-shaped object on a stand** before a seated god.
  - **29:** text.
  - **20:** a text grid (a list of the tribunals).
- **Puzzles:**
  - **21–24: a short mouth sequence**, if you don't use 15 for this. Hand over the right items in turn and the deceased regains mouth and speech.
  - **27: keep your heart.** Four seated gods each reach for the heart. You must keep it away from each in turn, for example by placing amulets between the heart and each god.
  - **26/28: heart spells.** Recover the heart and put it on its stand. The heart is the key object of the whole game, so these are good places to introduce it.

---

## ACT II: Dangers on the Road (30–42) [seen]

In the game (`godot/README.md` has the tuning): walk through every vignette; click a creature to step into its vignette as its spear-bearer and fight. Losing never restarts on its own: the bearer crumbles and you are back on the scroll. Once a creature is overcome, its vignette is put back as drawn.

| Spell | Vignette (Lepsius pl. XVI–XIX) | Puzzle idea | In the game now |
|---|---|---|---|
| 30 | **A large scarab on a pedestal**, the deceased adoring (pl. XVI) | You **gain the heart scarab** here; it's needed at 125d to keep your heart from testifying against you. A clean, large crop, easy to use as the inventory icon. | Not in the level (it starts at 31). |
| 31 | **Deceased with a spear facing two crocodiles**, one above the other (pl. XVI) | **Crocodile lanes:** two lanes; spear the crocodile that's advancing. | **Done.** The vignette opens out and you are the spear-bearer: ↑ ↓ move, Space thrusts; only the point strikes. Wave 1 is the lesson. Then the heka word in the caption flashes red, and wave 2 brings red crocodiles, turned back only by a thrust while holding Shift (heka). Heka wasted on an ordinary crocodile loses: it laughs, swallows the word, the bearer crumbles, and you are back on the scroll. |
| 32 | **Two pairs of crocodiles** (four in total), the deceased spearing (pl. XVI–XVII) | In the text there are four crocodiles, one per direction. **Use the compass:** each crocodile comes from one side, and you face that way and raise the right item. | **Done.** Faster, two at a time and from both sides; ← → turn you, ↑ ↓ move. Some come red (hold Shift). It speeds up with each crocodile but stays winnable (`min_gap`). Not the compass idea. |
| 33 | Deceased spearing an upright snake (pl. XVII) | Snake 1: timing the spear (the snake rears, then you strike). | **Done.** Close up. The snake coils out of reach; its tail waves (the warning), it squashes and springs. Thrust as it springs so the point lands on a red mark that shrinks with each strike. Three strikes; three bites and he crumbles. |
| 34 | Text only | Can be cut. | Not in the game. |
| 35 | Deceased spearing a snake on the ground | Snake 2, a variation. | **Done.** Red light, green light: creep up on the snake from behind and freeze whenever it lifts its head and looks. Strike when the small red dot of the spear point is on its eye (the rest of the head does not count); three strikes. |
| 36 | Deceased spearing a beetle (Apshai) | Beetle: it scurries between hiding spots and you predict where it goes. | **Done.** You stand still and turn (← →). Three beetles (the drawn one and two copies) dart about and pause by the spear point; pin each at full thrust. One that gets away three times reddens; once more and they swarm the vignette. |
| 37 | Deceased spearing two snakes (the Merti) | Two at once: work out the order. | **Done.** One snake on each side (the drawn one and a mirrored copy), coiled well out of reach. When a snake sign in the caption flashes red, that snake squashes and springs at him (the spell 33 spring): turn to it and thrust as it passes the spear point. Each is struck twice. |
| 38 | Deceased holding a sail-shaped object (living on air) | **Gain the sail** ("breath"). The sail glyph repeats through 54–62, so it's a natural key item. | **Done.** Take the ankh and sail from his hand. You can't go on past 38 until 31–38 are all done. |
| 39 | Deceased spearing a very long serpent (Apep) | **Boss: the long wave.** Apep lies the length of the panel, the spear point on his neck where the body folds back; the length is the timer. | **Done.** His tail lashes and a wave runs the length of him; Space presses it down as it reaches the spear point, and the barb goes in a step. Six and he lies as drawn, the spear as drawn. A wave that gets past lifts his head out to bite. Small feints die in the drawn hump: a thrust on a still neck works the barb loose. |
| 40 | Deceased spearing a donkey lying down, a thin snake in two loops on its back, its front at the rump where the spear point is (the Eater of the Ass) | Defend the donkey: hit the snake, not the donkey. | **Done.** Close up. Its head is down in the donkey: a thrust then spears the donkey and you crumble at once. The donkey swishes its tail (the tuft below its base line) now and then; the snake lifts its head to snap at it, and Space then strikes it. Later some swishes are flicks it ignores. Left alone it bites the donkey (three flesh signs, the donkey's). Three strikes. |
| 41 | Deceased spearing a thick snake coiled in two loops on a sheaf (stalks in a V, tied with four bands), its head at the spear point | Bind the sheaf. | **Done.** Close up. The bands are undone and the stalks splay; the snake hides inside, and the stalks stir where it is. Tie the bands bottom up (Space or click), each while the stir is above it; tied on it, it bites. Four bands force it out on top, as drawn, onto the spear: thrust before it strikes. |
| 42 | **Grid of the body:** each body part paired with a god | A **matching table**. It is all text, but it gives you *the idea*: "my hair is Nun, my face is Ra…". Turn it into **dressing the mummy with gods**: place god crops on body zones. Use a translation to set the real pairs. | End of the level; not a puzzle yet. It waits until every danger before it is overcome. |

**From playtesting (2026-10-15): to revamp** (also open in `godot/TODO.md`)
- **35, red light green light:** too easy. Maybe one life only, or no hints.
- **36, the beetles:** also too easy.
- **38, the breath of life:** life and breath become two separate signs and you may take only one: breath. Take life by mistake and the fights after are nearly impossibly hard. Clicking spell 38's caption shows its title with "breath" in bold (or similar): that is how you know which to pick. Needs the ankh and the sail drawn apart first.
- **39, Rekrek (Apep):** far too easy. Faster, or a different game.
- **40–41, the donkey and the sheaf:** both boring and slow. Rethink their pace.

### 39: The long wave (Apep) [done]
- **Drawn:** Apep lies flat along the ground the whole width of the vignette. The tail at the left ends in a dark wedge, there is one low hump in the middle, and at the right the body folds back in a hairpin, the small head lying under it pointing away. The barbed spear point rests on the fold (the neck). The bearer faces left, the front hand low on the shaft and the raised rear hand open over it, pressing down.
- **Disturbed:** the barb rests a little way up its line, not yet in; Apep is alive, and waves run along him.
- **Play:** the tail lashes and a wave runs the length of him to the fold, lifting his head as it comes. Space as the crest reaches the point presses it flat, and the barb goes in a step. Six and he lies still, the spear as drawn. A wave that gets past rears his head out to bite the bearer's foot (three bites and he crumbles). Smaller waves that die out in the drawn hump are feints; a thrust on a still neck works the barb loose a step. Faster, denser waves and a smaller window as the barb goes in.
- **Pieces:** `apep` (one sprite; the head cut loose in the fight, turning on its neck), the `spear39` poses from the spearers sheet, `apep_wave.gdshader`.

---

## ACT III: Food, Water, Breath & Transformations (43–109) [seen]

### Survival & sustenance (43–63) (pl. XX–XXIII)
- **Depicts** (checked against the cut sprites, 2026-10-22. *Italics* are Davis's 1894 titles, which are the in-game caption texts. "Davis:" quotes his vignette notes. Renouf/Naville is the fuller text in the Scene Atlas.)
  - **43:** the deceased, hands raised, before a god with a long wig and beard who holds a bundle of three tall was-sceptres in his forward hand (*not letting the man's head be cut off*). Davis: "three gods are adored by a man standing up", but this drawing has one god. It isn't clearly Osiris: no crown, and he walks rather than standing mummiform.
  - **44:** the deceased with a staff before a **tall gate** with a ribbed cornice (*not dying again*). Davis: "a man standing up in front of a gate."
  - **45:** **Anubis (jackal-headed) holding up a standing mummy** (*escaping corruption*). Davis: "Anubis sustains and protects a standing mummy."
  - **46:** the deceased with a long staff (*not letting injure him who is living*). There are two caption pieces: the second is Davis's "different reading" of the title (*not being detrimental to the hour of life*).
  - **47:** a **pylon between the benu heron and a human-headed hawk (the ba)** (*not being deprived of one's dwelling*). Davis: "a phoenix and a hawk with a human head." It is not a falcon.
  - **48–49:** single standing figures, 49 with a staff. Davis: their texts are the same as **10** (*going out justified*) and **11** (*going out against one's foes*).
  - **50:** the deceased beside the **execution block**: a rounded block on a low base with a long blade across its top (*not entering the place of execution*). Davis: "a man standing up near a block."
  - **51:** a single standing figure (*not going headlong*, i.e. walking upside-down, where the dead eat filth).
  - **52:** seated at an **altar of loaves** (*not eating excrement*). He lives on bread, wheat and beer from the sycamore of Hathor.
  - **53:** seated at the altar **holding out a cup** (*not drinking anything fetid*). The caption is inside the sprite, above the figure.
  - **54–56, 60–62:** standing figures holding the **sail**, the breath hieroglyph (54–56 *air*; 60–62 *command of water*, which Davis titles "Another chapter"). In **56** the lowered hand holds an **ankh**. Each sail is the same sign. 55 speaks as Shu, god of air.
  - **58:** the sail plus a **vase**. He is not drinking. The text names the parts of his boat (as in 99) and asks for milk, wine, cakes and meat.
  - **57:** a **sycamore with the goddess's arm** pouring water onto the hands of the bowing deceased and holding out a tray of food. Davis: "a goddess hidden in a sycamore." Only her arm is drawn.
  - **59:** the same goddess (Nut's sycamore) pouring water onto the hands of the **seated** deceased.
  - **63:** the deceased **pouring a libation from two bowls before the fire hieroglyph**, a tall flame on a stand (*drinking water and not being dried up by fire*). Davis: "a man offering a libation before the fire-hieroglyph." He is not drinking, and the tall form is fire, not water. The caption is inside the sprite.
- **Puzzles:**
  - **Resource triad:** gather *bread* (52–53), *water* (57/59 tree goddess), and *air* (the sail). The tree goddess only pours if you stand on the correct side and hold a cup. All three are needed later (148 and 125d).
  - **The execution block (50):** a "don't" puzzle. Walking past the block on the wrong side, or without the djed, ends the run. It teaches that some scenes are **avoidance**, not action.

### 43–46: The sceptres, the gate and the mummy
- **Drawn:** 43: the worshipper, hands raised, faces left toward the god, who holds a bundle of three was-sceptres. A double frame line divides 43 from 44. 44: a gate with a cornice, posts and an inner rectangle (the door leaf); the man walks left toward it with a staff, a cloth in his back hand. 45: Anubis on the left holds up a standing mummy, which faces right. 46: the man walks left with a long staff, a cloth in his lowered hand.
- **Disturbed:** the sceptres are in the god's hand, not carried; the 44 door is closed and ink-black.
- **Play:**
  - **43:** the player is the 43 worshipper (the drawn one hidden). Clicking the bundle walks him to the god, and the three sceptres go onto his back; the god's hand is left empty. Taking them is optional.
  - **The 43|44 double line:** drawn in front of the avatar. As he passes behind it, the part of him past the line is the 44 man and the rest is still the 43 worshipper; the swap moves across his body with the line. It works both ways until the door is used.
  - **44:** on entering, the door leaf turns solid ink-black, and only the door leaf glows on hover. The 44|45 double line is a hard barrier; the door is the only way on. Clicking the door walks him there and switches off the arrow keys.
    - **With sceptres:** one reddens and crumbles. He shrinks slightly (about 85%) and fades into the door, the scene goes dark, and the camera pans to 45.
    - **Without:** his head falls off, head and body redden and crumble, and everything resets to 43 (the god holds all three again, the door is drawn again, and the player is the 43 worshipper at the start).
  - **45:** the player is the mummy, and the arrow keys stay off. It rocks gently as the opening, then keeps rocking; pressing a stop glyph in the caption keeps it steady (how the glyph works and which sign it is: tbd). Anubis's part: tbd. The sceptres are hidden during this scene.
    - **Win:** the scene goes dark, and the player reappears as the 46 man where he is drawn, with the remaining sceptres on his back. They are his lives for the rest of the level (see 47).
    - **Loss:** the mummy falls, and he is back in front of the black door as the 44 man. Re-entering costs another sceptre.
    - **Loss with none left:** the mummy's head falls off, and everything resets to 43.
    - **Count:** three mummy tries. Enter (2 left), lose, enter (1 left), lose, enter (0 left), lose: head off, back to 43.
  - **46:** one-way. He cannot walk back right into 45, 44 or 43 (an exception to "walking the scroll should stay possible", approved).
- **Pieces:** `.mdp` layers: `sceptres43` (the bundle, with the god's hand redrawn empty), `door44` (the gate's inner rectangle), `mummy45` (cut apart from Anubis, its head a separate piece), the 44 man's head as a separate piece, and the 43|44 and 44|45 double lines as foreground pieces. The 43 worshipper and the 46 man become avatar textures. The red crumble uses `dissolve.gdshader`.

### 47: Claiming the dwelling
- **Drawn:** a pylon on a base, the benu heron on the left and the human-headed ba bird on the right, both facing the pylon. The caption holds the title (*not being deprived of one's dwelling*).
- **Disturbed:** the ba bird is missing.
- **Solved:** the ba stands to the right of the pylon, as drawn.
- **Play:**
  - **Claiming:** a "place" sign in the caption pulses red, like the heka word in Dangers. Clicking it claims the dwelling: the sign stops pulsing, and the ba fades in where it is drawn. Claiming is optional and possible on any pass.
  - **Unclaimed:** each time the player walks past the chapel without claiming, a note reads "Please claim your rightful seat so you may return to your dwelling." Walking on is allowed.
  - **The ba:** once present, it is clickable and reads "Your dwelling will not be deprived." When it appears, faint ink imprints of the was-sceptres also appear, poking out of the top of the pylon: as many as he carries at the moment of claiming (at most two, possibly none).
  - **Sceptres as lives:** from 46 on, the remaining sceptres are lives for the whole level. Each later failure costs one; with none left, the player dies. In the Survival level (43–63) only, every death plays the head-falling-off animation on whatever figure he is at the time (the man, the mummy, and so on).
  - **Death, unclaimed:** a restart at 43. Everything resets (the sceptres go back to the god, solved games and found sails reset); only the Journal is kept.
  - **Death, claimed:** the player respawns at 47 as the 46 man, in front of the pylon. The imprints on the pylon turn to full ink, and the sails he was carrying lie on top of the pylon too; sails already in a figure's hand stay there. Clicking the sceptres or sails takes them back. He gets back as many sceptres as he had when he claimed (tentative).
- **Pieces:** `.mdp` layers: the ba cut apart from `spell47_bird_shrine`, and the place sign cut from the caption (which sign: tbd).

### 48–49: True of voice
- **Drawn:** 48: a man walks left, hands empty; the two leftmost signs of the caption are *maa-kheru*, "true of voice" (a feather and an oar). 49: a man walks left with a staff.
- **Play:**
  - **No figures:** the drawn men in 48 and 49 are hidden. The avatar walks through as the 46 man, without splicing.
  - **48:** clicking the true-of-voice signs makes them grow slightly bigger. Then only the feather goes to the player. Whether taking it is required to go on: tbd.
  - **Where the feather goes: tbd.** Either it sits on top of his head, or it is tucked into a "for later" inventory. **Flag:** both bend the rules: the feather on his head is a new arrangement of a drawn sign, and an inventory is new machinery. Confirm before building.
- **Pieces:** `.mdp` layers: the true-of-voice signs (feather and oar) cut from the 48 caption, and the feather on its own.

### 50: The execution block
- **Drawn:** a tall rounded block with a long blade laid across its top; the man stands to its left, away from it.
- **Play:**
  - **The 49|50 double line:** the avatar splices from the 46 man into the 50 man.
  - **Minigame:** tbd. Its mode may use the 50 man as the avatar.

### 51–52: Not going headlong
- **Drawn:** 51: a man stands upright. 52: the man sits on a chair before an altar heaped with loaves.
- **Play:**
  - **Upside down:** the player crosses the 50|51 double line spliced into the 51 man, but upside down: a vertical flip, head on the ground line, still facing left. Alternatively, finishing the 50 game turns him upside down (tbd). He can still walk.
  - **Flipping upright:** press on him and drag upward. He turns over with the pointer; released past halfway, he snaps upright, and short of it he falls back upside down. This is a transform in place, like the calf/jar gestures, so it is outside the moveable-object system.
  - **Upside down into 52:** he eats excrement (animation and mechanic tbd). It costs a sceptre, and with none left the respawn rules from 47 apply.
  - **From 51 on:** the avatar is the 51 man for the rest of the level.
- **Pieces:** the 50 man and the 51 man as avatar textures.

### 52: Keeping the loaves clean
- **Drawn:** the man sits on a chair, his forward arm stretched out over an altar on a stand heaped with loaves.
- **Disturbed:** the chair is empty.
- **Solved:** the man sits with his hand over the clean loaves, as drawn.
- **Play:** the opposite of 53.
  - **Starting:** clicking the empty chair or the altar makes the avatar (the 51 man) fade into the seated man.
  - **Covering:** excrement (dark red) falls from the top. ← and → stretch and bend his arm at the elbow, so the hand slides sideways over the altar at a fixed height.
  - **Splatter:** a single piece landing on the loaves is a loss, under the sceptre lives rule.
  - **Full death (no sceptres left):** his head falls off, and excrement rains down.
  - **Done:** after N pieces (tbd) without a splatter, the rain stops. He stands up as the 51 man, and the seated man stays.
- **Pieces:** `.mdp` layers: the seated man cut apart from the chair, and his forearm and hand (turning at the elbow). The excrement is the same piece as in 53.

### 53: Bread, not filth
- **Drawn:** the man sits on a chair and holds out a cup on his forward arm; in front of him, an altar on a stand is heaped with loaves.
- **Disturbed:** the chair is empty, and the altar is bare.
- **Solved:** the man sits holding out his cup before the heaped altar, as drawn.
- **Play:**
  - **Taking his place:** the avatar (the 51 man) fades into the seated man.
  - **Camera:** it zooms in a little on his hand and cup. The altar is moved up slightly so it stays in view and can be seen filling.
  - **Catching:** loaves and pieces of excrement (tinted dark red) fall from the top. ← and → stretch and bend his arm at the elbow, so the cup moves sideways but always stays at the same height.
  - **Bread:** each caught loaf flies to its drawn place on the altar, which fills toward the drawn heap. Each loaf that drops past him raises the share of excrement among what falls (numbers: tbd).
  - **Excrement:** catching even one piece is a loss (tbd), under the sceptre lives rule.
  - **Full death (no sceptres left):** the seated man's head drops, and excrement rains down.
  - **Done:** once the altar is heaped as drawn, he stands up as the 51 man, and the seated man stays.
- **Pieces:** `.mdp` layers: the seated man cut apart from the chair, his forearm and cup (turning at the elbow), each loaf of the heap on its own, and the excrement (to be cut and provided by the user from where it is drawn).

### 54–62: The seven breaths
- **Drawn:** seven standing figures (54, 55, 56, 58, 60, 61, 62) each hold up the sail, the breath sign (P5). In the lowered hand, 56 holds an ankh and the rest a folded cloth; 58 holds a vase in his second raised hand instead.
- **Disturbed:** the seven raised hands are empty, and the sails are spread across the reachable level (46–63, never in 43–45).
- **Solved:** all seven hold their sail, as drawn.
- **Play:** some sails lie somewhere to be found and grabbed; others are the reward of a small minigame (which ones: tbd). He can carry several sails at once; they stack slightly (how exactly: tbd, depends on the artwork). Any sail fills any empty raised hand. On a death, see 47 for where the sails go. Walking on past 62 is allowed, but the level only finishes once every minigame in it is done, this one included.
- **Pieces:** the seven sails cut from their figures, with the raised hands redrawn empty.

### 57: Catching the water
- **Drawn:** a sycamore on the left. The goddess's arm (only her arm is drawn) comes out of it holding a vase high and pours a stream onto the raised hands of the man, who stands bowing slightly; below it, a hand holds out a tray of offerings from the tree.
- **Disturbed:** no one stands there, the water only dribbles down from the vase, and the tray is drawn back into the tree.
- **Solved:** the man stands with his hands in the stream and the tray held out, as drawn.
- **Play:**
  - **Taking his place:** the avatar (the 51 man) fades into the 57 man, and the dribble becomes the full stream, as drawn.
  - **Holding him up:** he bends at the waist. Released, he sinks lower; Space raises him. The stream stays as drawn. This is the procession's water-jar hold, applied to his bend instead of the jar's tilt.
  - **Progress:** with his hands in the stream, the tray extends out of the tree. Too low and his hands miss the water; too high and it splashes over him. Out of the window, the tray draws back a little (as the jar's line dries back, never to nothing).
  - **No failure:** he can keep at it as long as needed.
  - **Done:** once the tray is fully out at its drawn place, he stands back up as the 51 man, and the drawn 57 man stays.
- **Pieces:** `.mdp` layers: the 57 man's upper body cut at the waist (pivot at the waist), the tray with its hand, and the water stream.

### 59: Water from Nut's sycamore
- **Drawn:** a sycamore on the left; the goddess's arm (only her arm is drawn) pours a stream from a vase onto the hands of the man seated on a chair, a tray beside the vase. The caption's top line has two *mw* (water) signs, three horizontal lines each: six lines.
- **Disturbed:** the chair is empty, and no water flows.
- **Solved:** the man sits under the stream, as drawn.
- **Play:**
  - **The sequence:** both *mw* signs flash red together, then each of the six lines flashes red, one at a time, in a fixed order (which order: tbd). Both signs flash again to end the sequence.
  - **Clicking:** the player clicks the six lines in that order. A wrong click costs nothing: both signs flash, the same sequence replays, and the player starts over.
  - **Water flows:** the stream pours down from the vase, ending as drawn, and the avatar (the 51 man) fades into the seated man.
  - **Leaving:** Esc, Space, ← or → makes him stand up as the avatar again. The seated man stays in the chair from then on.
- **Pieces:** `.mdp` layers: the six lines of the two *mw* signs, each its own piece; the water stream; the seated man cut apart from the chair.

### Coming forth by day (64–75) (pl. XXIII–XXVII)
- **Depicts:**
  - **64:** adoring a **sun disc pouring rays**.
  - **68:** a **shrine with a god inside, a ladder beside it**, the deceased approaching.
  - **71:** a **winged falcon** and a **recumbent horned beast**, each on a pedestal.
  - **72:** the deceased before a **shrine with two seated mummiform gods**.
  - **74:** a figure with a long snake-like staff.
  - **75:** walking toward a **tall pillar** (Heliopolis).
- **Puzzles:**
  - **Ladder to the shrine (68):** set the ladder against the shrine, then climb it as the *body* (not the ba).

### Transformations (76–88) [seen]
| Spell | Form (vignette) | Ability |
|---|---|---|
| 77 | Large falcon on a perch | Fly over a gap |
| 78 | Large falcon (with flail) | Fly; carry an item |
| 79 | The deceased before four standing gods | (a "council" before the forms; a head-order lock) |
| 80 | A god beside a **large sun disc pouring rays** | **Light in darkness** (light dark scenes) |
| 81 | **Human head rising from a lotus** | Rise out of water |
| 82 | Ptah (mummiform, with sceptre) | "Create": activate statues |
| 83–84 | **Heron** (two drawings) | Wade across shallow water; appear at sunrise |
| 85 | **A crouching bird-bodied figure with a human head** (the ba/soul form) | Pass as spirit |
| 86 | **A swallow/falcon perched on a mound** | Slip through small openings |
| 87 | **A coiled snake rising up on legs** (Sa-ta) | Slither through cracks / underground |
| 88 | **A mummiform figure with a small crocodile above its head** (pl. XXXIII) | Swim past guardians |

- **Toolkit puzzle:** these become the **form wheel**. Later obstacles need specific forms. Each form crop is already a ready-made sprite.
- [ ] **Low priority (liked, but very involved): replay levels in a form.** Each transformation lets you take on that form. You can then go back through the scroll and play certain levels *as* that form, which unlocks new ways to play and new things to do there.

### Ba and tomb (89–92) [seen]
- **89:** the ba bird hovering over the mummy on a lion bier. **90:** the deceased before a god (*removing harm from the mouth*). **91:** the deceased with the **ba bird flying beside him**. **92:** the **ba flying out through the doorway of a shrine/tomb** while the deceased stands at the door.
- **Puzzle:** **ba/body switch.** Reunite the ba with the body (89), then send the ba out through the door (92). Some later locks need the ba (flying), others the body (holding items).

### Thoth & boats (93–109) [seen]
- **93:** a boat with a seated god and a standard, the deceased adoring.
- **94:** **Thoth** (ibis-headed) facing the **kneeling deceased, who holds out a scribe's palette**.
- **95:** Thoth and the deceased standing.
- **98:** a **boat with a seated figure (the ferryman)**, the deceased gesturing to him.
- **99 (pl. XXXVI):** a long table in which the boat's parts each "speak" their names.
- **100–101:** the deceased **poling Ra's boat**, with the sun-headed god seated and a heron aboard. 100 also shows **Osiris and a djed pillar**.
- **102:** Ra's boat with the sun god, the deceased kneeling at the stern.
- **103:** a goddess (Hathor) in a shrine.
- **104:** the deceased seated between two seated gods.
- **105:** the deceased adoring a stand with a **ka-box and vessels/flames**.
- **106:** offering to a god.
- **107–108:** the gods of the West (three gods, the deceased kneeling); 108 has a **mound/mountain with figures on it** (the mountain of Bakhu).
- **109:** a **boat with a god and a calf**, **two tall trees (the sycamores of the east)**, the deceased adoring.
- **Puzzles:**
  - **93: refuse the boat.** The player must actively refuse to get on the boat (how: tbd). Clicking the chapter title or the east sign gives very obvious clues.
  - **94: offer the scroll and the cup.** The avatar is shown holding the scroll, the one Thoth gave him in the opening sequence. The player clicks the scroll and drags it onto Thoth, and that arm freezes in the offering position. The player also needs the cup: clicking the cup sign in the caption above (the part and the whole glow) puts the cup in his hand. Then spell 95 appears: through animation and screen effects the items disappear, the avatar and Thoth take their spell-95 positions, and the offering stand appears.
  - **98: get on the boat.** A boat scene that directly contrasts with 93. The player can read the caption and makes the active decision to get on the boat.
  - **100–102: sail to the West.** A screen-effect transition into 100. The player drags and turns their own boat (like the calf-turning game), then sets sail. As the boat turns, the figures transition into 101. Sailing on open water lasts a while: as the boat rows from right to left across the screen, the caption's text above it animates. Once the boat is fully out of view, a new scene begins: spell 102. It holds the player there for a bit, then enables navigation.
  - **103 onward: walking again.** The moment the player gets off the boat (their first move once navigation is enabled), the avatar becomes the adoring figure from 108. The figures of the deceased in 103 and the other vignettes are invisible at first; as each minigame is completed, its figure probably appears, as a sign that the minigame is done. The remaining spells in this level are minigames the player walks between to complete, unlike the long animation sequences with occasional interaction before them. The minigames for spells 103–109: tbd.

### Ba, Thoth, ferry and Ra's boat: opening animation sequence
1. **Ba and body (89):** the ba leaves, or appears out of, the mummified body. The screen goes black.
2. **Thoth (94):** the deceased is shown in front of Thoth. The player takes the scroll Thoth offers. The screen goes black again.
3. **Ba as avatar (91):** the ba bird is now the avatar, floating up and down in front of the person.
4. **The door (92):** the person walks to the next vignette and "opens" the door. The person animates into the door-open pose, and the stick in hand and the other object subtly meld into the door frame. The door's interior, previously black, turns into the outline-only version seen in the vignette.
5. **Into the door:** the player flies the ba to the door (arrow keys only). The ba shrinks, as if going into the door, and turns into the vignette's ba bird. The screen goes dark.
6. **The first boat scene** appears.

- **Art note:** the lotus needs to be redrawn for the offering stand and the boat.

---

## ACT IV: The Field of Reeds (110) [seen]

### 110a: large adoring figure (pl. XL, XLII)
- **Depicts:** a large figure of the deceased with hands raised in adoration, framed by text columns.
- **Use:** an **entry or threshold screen**. It works as the player's avatar portrait, or as a giant "door" figure that lowers its arms when the act is complete.

### 110 (main): Field of Offerings, three registers in a water frame (pl. XLI)
- **Depicts:** a field framed by water on all sides.
  - **Top register:** a mummiform god, an offering stand, a falcon on a pedestal, a human-headed bird, the deceased with offerings, **three round loaves or discs**, a boat with the deceased rowing, three seated gods with a heaped offering, and a procession.
  - **Middle:** seated god (Hetep), the deceased adoring, a heron on a stand, **two heaps of grain**, **ploughing with an ox**, **reaping tall grain**, a tree, **sowing**, ploughing again.
  - **Bottom:** **two snake-prowed boats** (one with stairs, one with a shrine and oars), an oval island with a bird, and **curving waterways with steps** and a small group of figures.
- **Puzzles:**
  - **Farming cycle:** put the middle register's actions in order: plough, sow, reap, thresh into heaps. The stages are scattered; restore the sequence and the grain heaps fill.
  - **Waterway route:** in the bottom register, choose the right snake-boat and steer through the curving channels to the stepped landing.
  - **Offering bundle:** take grain from the middle register to the top register's offering stands to feed the gods. They then grant passage.

#### Feed the gods (110, top register) [accepted idea; checked against `art/fields110.mdp`, 2026-11-05]
- **Drawn:** read right to left, four worshippers walk left toward a heaped offering stand before three seated gods on a shared dais. Then comes the barque with its rower and a table of tall jars, an offering bearer holding a cup, the human-headed ba bird, a falcon on its shrine, a bird lying on an offering stand, and a mummiform god at the left end. Three round discs (layer "Star pools") hang above the barque. [verify] whether they are loaves.
- **Disturbed:** the three stands are bare: the heaped stand before the gods, the barque's table, and the bird stand.
- **Plays:** the grain from the middle register's two heaps (see the field work) is carried up to the top register and set on a stand. Each stand takes its own drawn offering. Only valid placements stay; a wrong drop returns the grain to the avatar, and a placed offering is locked. Solved is the plate as drawn. [verify] carrying across registers against the movable-object rules in `AGENTS.md`.
- **Pieces:** cut each offering off its stand (the heap on "Heaped offering stand", the barque's jars; the bird and its stand are already separate layers). The barque's layers sit in the "Solar crossing" group, hidden in the MDP while that part is still work in progress, so its cut will change. Reuses `moveable_object.gd` and `offering_table.gd`.

### 110c: four stacked panels (pl. XLII)
- **Depicts, top to bottom:**
  1. Ra's boat with a shrine holding a scarab, two goddesses in front.
  2. The deceased before Osiris enthroned, a goddess behind him, and an offering stand.
  3. The deceased kneeling before two seated gods with an offering table.
  4. The same again with a different offering.
- **Puzzle:** **stacked-room elevator.** Each panel is a floor. Bring the right offering to each floor (spot the difference between floors 3 and 4) to rise to Ra's boat at the top.

### 112–124 (connectors) [seen]
- **112–114:** the Souls of Pe, Nekhen, and Hermopolis. Each panel has three gods: falcon-, jackal-, or ibis-headed.
- **117–119:** Anubis leading the deceased by the hand toward a pylon and a mound (Wepwawet, "opener of the ways"). Recruit Anubis as a guide.
- **122:** the deceased bending at a tomb doorway.
- **124:** four animal-headed gods in a row.
- **Plan:**
  - **112–116: the councils.** Some may or may not be skipped; further research needed.
  - **117–124: led to the mound.** An animation (whether the player does any of it, e.g. the bend in 122: tbd): Anubis leads the deceased to the mound (117), then leaves (118). The deceased bends over (122), enters successfully, and appears in front of the four gods (124).
  - **After 124:** how this flows is tbd, because going directly to 125 makes a lot of sense. That conflicts with 125 as the finale reached through 161; what happens to 126–165 is tbd.

---

## ACT V: Gates, Portals & Guardians (126–150)

### 126–143: The lake of fire, caverns & boats (pl. LI–LIX) [seen]

- **Plan:**
  - **126–128:** tbd.
  - **129–136: boat games.** What they are and how they connect: tbd.
  - **137–140: a short level of three vignettes (137, 138, 140).** A preparatory level, where you get ready to meet the gate guardians. Puzzles tbd; the four-torches idea for 137 stays.
  - **141–143:** tbd.

#### 126: Lake of Fire with four baboons (pl. LI)
- **Depicts:** the deceased adoring before a rectangular **lake of fire**, with a **seated baboon at each corner** and fire braziers along the sides.
- **Puzzle:** the baboons decide whether you may drink, or pass, without being burned. Light braziers in an order the baboons signal by which way each faces. **Follow the gaze**: each baboon's gaze points to the next. Doing it right cools the lake. This also introduces baboons as **judges**, foreshadowing the baboon on top of the scale in 125d.

#### 127–143: Caverns, boats, lamps
- **127:** seated and standing gods of the caverns. A head-sequence lock.
- **129–134:** many **boat** vignettes, including Ra's boat with a shrine and a crew of gods (133–134). Optional sailing segments.
- **137 (pl. LVI):** **a seated figure with four lamps or torches** around them.
  - **Puzzle:** **four torches by direction.** Light each torch on the correct side using the compass.
- **138:** Abydos fetish and a djed pillar.
- **140:** Anubis (jackal) on a shrine, the deceased adoring before a wedjat eye.
- **141–143:** lists of gods (text grids) and **stacked boats** carrying different crowns, falcons, or sun discs. 141–142 are mostly long lists of gods' names and their epithets.

### 144–146: The gates (pl. LX–LXVII) [seen]

- [ ] for 145, you have a name, and you have to worship the gods in order. if you get the wrong god, it'll not light up or something/ not be worshipped. you drag name onto them: you have to learn what name to what god. if you get the wrong god, they'll shake their head, the current name you have will zip off in the direction of the correct god, and you get a new name you have to guess. 

**Checked against the art and Davis** (2026-10-22; `art/gates144-145.mdp`, `art/gates146.mdp`; descriptions are in `godot/assets/gates/registry.json`, the sprites are not cut yet)
- **144:** seven rooms, read right to left. Inside each, a guardian kneels holding two knives under a roof of blades between two cobras. Two standing gods wait in front. Davis gives the heads as follows (inside; then the two standing):
  1. a god (head not given); a man and a hawk
  2. crocodile; a ram and a bull
  3. scarab; a ram and a man
  4. dog; a ram and a man
  5. a head Davis can't name (drawn as a round, front-facing face); a ram and a bull
  6. monkey; a ram and a hawk
  7. uraeus; two rams

  Davis names three keepers per room: the doorkeeper, the watcher ("the name of the keeper") and the herald ("the one in command"). The kneeling god is taken as the doorkeeper. [verify] which standing god is the watcher and which the herald; the descriptions name both without choosing. [verify] room 1's standing pair looks like two beaked heads, not a man and a hawk. The old note above (plumes, grain) is wrong: the roofs are blades, and each guardian holds knives.
- **145:** 21 panels, matching Davis's 21 gates. In each, a god holding a knife and a raised blade stands behind a pylon, and the deceased adores on the other side. Davis's heads, which match the drawings in order:
  - 1–5: hawk, two uraei (in place of a head), ram, ram, foreign-looking man
  - 6–10: hawk, jackal, two uraei, jackal, man
  - 11–15: lion, cat, hare, lion, crocodile
  - 16–21: monkey, man, dog, ibis, a front-facing human head, Bes

  The pylons with a ladder up one side (4, 21) and the cross-braced one (11) are drawn differently. [verify] whether that means anything. Keeper names exist only for gates 2–10 and 21. The 21 adorers are set to `journal: false` so the journal isn't swamped.
- **146:** 15 portals, matching Davis's 15. Each portal and the god crouching inside it is one entry. Crests and gods, in order:
  1. snake, crocodile
  2. ankh among six vipers, man with three vipers on his head
  3. snake, monkey
  4. snake, bull
  5. snake, ibis
  6. six vipers, uraeus
  7. snake, man
  8. snake with disc and horns, man
  9. snake, hare
  10. snake, man with feathers and ram's horns
  11. two cats, monkey
  12. snake, uraeus
  13. two Nile gods, crocodile with an ostrich feather
  14. snake and bull's head, hawk
  15. row of plumes, man

  There is no scorpion. The "cat and dog" crest is two cats. [verify] the god in 3 looks more like a donkey than a monkey.
- Not yet entered: the caption bands above some panels.

**Shared names across 144–147** (2026-11-05). Names are Davis 1894's. Where Davis translates the same Egyptian name in two different ways, the match comes from Lucarelli 2010 (144) or Allen 1974 (145–146). The spells pair off: 144 and 147 are two versions of the seven gates (three keepers each), and 145 and 146 are two versions of the portals (one keeper each). No name repeats between the two pairs. 144's first gate is not "mistress of trembling"; that name belongs to the first portal of 145 and of 146.

- **147 ↔ 144, the seven gates.** 147 swaps 144's fourth and fifth gates; the rest keep their places.
  - 147.1 = 144.1. Doorkeeper: "the Subverter of the Many Faces" = "overthrowing the multitude of the forms". The other two ("the Fire-passer", "the one who Fascinates by his Words" against Smet and Sahatu-Kheru) are translated too differently to tell.
  - 147.2 = 144.2. Herald: "Aseb" = "Ashu". [verify] The doorkeeper ("the One who gave birth to the beginning" against Toun-ha) and the watcher ("the Agitating his Face" against Skati) aren't clear matches.
  - 147.3 = 144.3. Doorkeeper: "the One who Feeds upon the Excrement from his Posteriors" = "eating the excrement of the one who reaches it". Watcher: "Vigilant with his Face" = "the one with a Vigilant Face". The herald is cut off in the scan.
  - 147.4 = 144.5. Doorkeeper: "the one who Lives upon Reptiles" = "living upon reptiles". Herald: "Flame of Face, seizing its opportunity" = "Nebet-hi-Kehabu-at" (Lucarelli: "burning face with violent strength"). [verify] the watcher, "Flame" against Usheb.
  - 147.5 = 144.4. Doorkeeper: "the One whose Face repels the Multitudes of Words" = "repelling the multitudes of words". Herald: "the One who Repels the Crocodiles" = "great to repel the crocodile". The watchers differ: "the One who Lifts up his Face" against "the one with a Vigilant Heart".
  - 147.6 = 144.6. Watcher: "the One whose Face brings in the Flame" = "An-hi" (Lucarelli: "one who brings (his) face"). Herald: "Face-sword" = "the one who strikes for the keeper of Heaven" (Lucarelli: "violent of face, who belongs to the sky"). [verify] the doorkeeper, "Feeding and Watching of the Words" against An-Ketitau-Kehabu-Kheru.
  - 147.7 = 144.7. Doorkeeper: "Their Sword" = "Mates-sen, their executioner". Watcher: "the Only One Speaking" = "the Great by his word". Herald: "the One who Repels the Subversive ones" = "the Expeller of the overthrower".
- **145 ↔ 146, the portals.** 146 has 15 portals and 145 has 21, so 145's portals 16–21 have no partner in 146. The portal names match one for one, except that 8 and 9 swap places, and so do 14 and 15:

  | Portal | 145 (pylon name, start) | 146 (portal name) | Keeper |
  |---|---|---|---|
  | 1 | "mistress, terrible and great, the dominating wall" | "the mistress of the Terror, the height of walls" | 146: "Veneration" (145: none) |
  | 2 | "mistress of Heaven, mistress of the earth" | "the Mistress of Heaven, the Regent of Earth" | 145 "Ra's offspring", 146 "Bringing forth of Ptah"; both "child of", but of different gods |
  | 3 | "mistress of the altars, the mistress of the offerings" | "the Mistress of the Altars, the Mistress of the Offerings" | different: 145 "Fig-tree", 146 "the one who performs the unction" |
  | 4 | "presiding over the executions of the mistress ruling the earth" | "the one who is in possession of the Sword, the Regent of the Earth" | same: "the Immolator of cattle" = "the one who strikes the cattle" |
  | 5 | "mistress of the fire" | "the Flame, the Mistress of the Breaths for the Nostrils" | same: "he who puts the foes to flight" |
  | 6 | "master of the roarings whose neither height nor width are known" | "the Mistress of the Prostrations" | same: "the Gatherer" |
  | 7 | "the cloud enveloping the suffering" | "the Cloud Enveloping the Fainting One" | different: 145 "Neith", 146 "Kenti" (Allen: two readings of one name) |
  | 8 / 9 | 145.9 "the fire and the flame which are not extinguished" | 146.8 "the Blazing Flame which is not extinguished" | same: 145.9 "the protector of his body" = 146.8 "the one who protects his body" |
  | 9 / 8 | 145.8 "the one who belongs to her mistress, the Strong" | 146.9 "the One who is on the forehead of the Mistress of the Forces" | same: 145.8 "Djeses" = 146.9 "Djetes" |
  | 10 | "height of the gates, the exciter of the clamors" | "the One who makes longer the outcries" | same: "the Great one who locks up" |
  | 11 | "reiteration of the flame … the terror of every gate" | "the god of the Sword, the Flame Destroying the Foes, the Terror of every Gate" | none |
  | 12 | "the one who goes around the earth and dispels those who come" | "the one that the earth invokes, that routs those who come" | none |
  | 13 | "the one towing the gods" | "the one who tows Isis" | none |
  | 14 / 15 | 145.15 "the lord of terror, slaughtering amidst blood" | 146.14 "the Mistress of Terror, slaughtering amidst blood" | none |
  | 15 / 14 | 145.14 "Tesher in mourning … going out by night" | 146.15 "the Red Soul in Mourning, investigator going out by night" | none |

- **For the games:** the same name can be asked for twice, once in each spell of a pair. A portal's name learned in 145 opens the matching portal in 146, and a keeper named in 144 returns in 147 (watch the 4/5 swap). The keepers that differ between 145 and 146 (portals 2, 3 and 7) are the hard cases, or need their own clues.

#### 144: The seven arits (gateways) (pl. LX–LXI)
- **Depicts:** **seven gates**. Each has a doorway topped with a row of plumes (uraei) and a **seated guardian inside holding a knife or ear of grain**, plus **two standing animal-headed figures** in front (the **gatekeeper, watcher, and herald**). Heads include falcon, jackal, ram, hare, crocodile, lion, and snake. They differ per gate, which is perfect for identity puzzles.
- **Puzzle:** **name the three.** At each gate, the three guardians' heads must match three items or forms from your journal. Seven gates get gradually harder: gate 1 needs one match, gate 7 needs three plus the right form.

#### 145: The 21 pylons/portals of the Field of Reeds (pl. LXI–LXV)
- **Depicts:** a long run of identical panels. Each has a **standing guardian holding a large knife**, a **pylon topped with plumes**, and the **deceased adoring**. Only the guardian's head changes: jackal, crocodile, lion, ram, bull, hippo, and others.
- **Puzzle:** **the gauntlet.** A fast-paced corridor. Each guardian reveals its head and you raise the matching amulet or form before it strikes. This is where the head teaching from Acts I–IV pays off. Its high repetition makes it good for pacing.

#### 146: Portals of the House of Osiris (pl. LXV–LXVII)
- **Depicts:** doorways, each with a **seated knife-holding guardian inside**. A **different crest sits on top of each door**: wavy snakes, a cat and a dog, a scorpion, a human-headed snake, uraei with ankhs, and so on.
- **Puzzle:** **read the crest.** The crest on top of each door tells you what *kind* of offering or form opens it. For example, the cat-crest door wants the cat that killed Apep in 17, and the snake crest wants the Sa-ta snake form from 87. The crest tells you the answer; the guardian is just in the way.

### 147: Adoring the baboon gods (pl. LXVII–LXVIII) [seen]
- **Depicts:** a god standing, an **offering stand with a crowned vessel**, and the deceased **kneeling** with hands raised. The god's head changes per panel.
  - *(Checked: seven panels, a–b on pl. LXVII and c–g on pl. LXVIII. The standing god is **baboon-headed** in each, with a wig and a sceptre.)*
- **Puzzle:** a quieter "reward" version of 144. Place the correct offering on each stand.

### 148: The seven cows and the bull (pl. LXIX–LXX) [seen]
- **Depicts:** a shrine framed by columns.
  - **Seven cows plus the bull**, each standing in its own cell with a table of food.
  - **Four steering oars**, each with a **wedjat eye**: the four directions of the sky.
  - On the left, **four standing figures** with different heads; they look like the **Four Sons of Horus** (human, baboon, jackal, falcon) **[verify]**.
  - On the right, two large goddesses (one with a falcon on the head, holding lotus papyrus) and the **deceased and wife offering** at an offering stand.
- **Puzzle:** **Provisioning for eternity.**
  1. Match each oar to a direction (compass from Act I; the Four Sons beside them give the direction).
  2. Feed each cow from the food you farmed in 110. The cows are slightly different, so spot-the-difference tells you which food goes to which. The bull goes last.
  3. Complete the scene and your **sustenance meter fills permanently**, which counts as evidence at the Weighing.
- **From playtesting (2026-10-15):** definitely think of a game for the cows, and make it (also open in `godot/TODO.md`).

### 149–150: The fourteen mounds and their key (pl. LXXI–LXXIII) [seen]
The two belong together: 150 is the key to 149.

- **Plan:** 149 will probably play like Dangers: each mound's vignette is its own minigame. Winning one gives you a "key", and the keys are used somehow in 150 (how: tbd). What a key is waits on more research: which mound matches exactly which sign in 150's key. 150's signs look different from 149's, so the match is not one to one.

#### 149: The fourteen mounds (pl. LXXI–LXXIII)
- **Depicts:** fourteen panels. Each pairs a **guardian**, usually **holding one or two knives**, with **an abstract sign for its mound**. Panels I can make out:
  - falcon-headed with a knife, plus a meander/channel sign
  - a figure next to an oval
  - **three figures holding up a long wavy snake** beside a pillar
  - a figure next to a U-shaped basin
  - a figure with two knives over a **crescent boat**
  - a crowned figure next to a hooked sign
  - **a lion-tailed figure with knives at a stepped (staircase) mound**
  - **a winged figure with knives** next to an arched doorway
  - a figure facing a **long serpent/crocodile-headed creature** rising diagonally
  - figures next to **ovals that hold a snake**
  - a group with Anubis and reclining figures
  - a **seated god with a scarab before him and a crocodile-headed figure**
  - **a hippo/pig-like beast with knives** before a stand

#### 150: The mound key (pl. LXXIII, left)
- **Depicts:** a grid of **plain mound signs** with no figures: rectangles, ovals, a cross, an L, a T, wavy snakes, a snake in a frame, a U shape. They look different from the signs in 149's panels, although the two correspond somehow.

---

## ACT VI: Amulets & Strange Creatures (151–165) [seen]

### 151–154: Guarding the body (pl. LXXIV–LXXV) [seen]

#### 151: Burial chamber (pl. LXXIV, right)
- **Depicts:** in this papyrus it is **stacked vertically, not a floor plan**:
  - **(a)** Anubis as a jackal on a shrine, between two mummiform figures
  - **(b, d)** text blocks
  - **(c)** the mummy on a lion-headed bier, a goddess **kneeling at the head** and one **kneeling at the foot**
  - **(e)** the jackal shrine again with two figures
- **Puzzle:** **guard the body.**
  - Place the two kneeling goddesses at the head and foot. The clue comes from spell 17, where the kites sit at the ends of the bier.
  - Then set the jackal on the shrine in both the top and bottom panels, with the right attendant on each side. Gaze and facing tell you which attendant is which.
  - It's simpler than the classic floor plan, but it can still use direction clues: the panels are top and bottom, the figures left and right.

#### 152–154
- **152:** a seated figure and a standing figure, apparently building or measuring. *(Checked: a woman kneels and holds up a cup to a seated man. The text is for building a house on earth.)*
- **153:** text only in this papyrus (the vignette box is empty).
- **154:** the mummy on a bier under a sun disc. A short "the body does not decay" scene; it can be the last ba/body check.

### 155–160: Amulets (pl. LXXV–LXXVI) [seen]
Each is a single large, clean object, ideal **inventory icons**.

| Spell | Amulet | Suggested use |
|---|---|---|
| 155 | **Djed** pillar (stability) | Prop up a collapsing door/pylon |
| 156 | **Tyet** knot of Isis | Isis-crest doors (146); calm the kneeling goddesses (151) |
| 157 | **Vulture** with spread wings holding ankhs | Shield from above (attacking birds, falling objects) |
| 158 | **Broad collar** (falcon-headed terminals) | Shows you are dressed/prepared; a 125 entry requirement |
| 159 | **Papyrus column (wadj)** | Renewal; regrow withered crops in 110 |
| 160 | **Two-plume/feather-shaped amulet** **[verify identity]** | Pairs with Ma'at's feather |

*(Checked: 155 djed and 156 tyet are on pl. LXXV; 157–160 on pl. LXXVI. In the translation both 159 and 160 are the column of green felspar, but the 160 vignette here is a tall two-lobed shape.)*

- **Puzzle:** an **amulet placement** mini-game. Each amulet goes on a specific part of the mummy (throat, chest, and so on); the funerary texts give the real positions. Place them on the 89 or 154 mummy crop.
  - [verify] Allen 1974 has **all six at the throat**, on the day of burial ("joining the earth"), so the texts don't support different positions. Drop or rethink this idea.

**What each text says the amulet does, and where it could go** (Allen 1974 and Davis 1894, spells 155–160; checked 2026-11-06)
- **155 djed:** Osiris is given back his backbone while lying on his side; the wearer isn't kept from the gates of the West, gets offerings from Osiris's altar and beats his enemies. *Reward:* 68 (turning from side to side and standing up) or the 137–140 prep level (the djed is drawn in 138). *Requirement:* the gates (144–146).
- **156 tyet:** the blood, power and magic of Isis protect the wearer; no road is blocked to him, gates open, and he is given barley and wheat in the Field of Reeds. *Reward:* 151 (Isis at the bier). *Requirement:* the grain in 110 (check the order: 151 comes after 110 on the scroll), or a one-time "unblock a closed way".
- **157 vulture:** Isis searches the marshes for places to hide Horus; her protection makes anyone attacking him tremble. *Reward:* something hidden or kept safe in the 110 marshes. *Helper:* the 149 mound fights (turn away one attack, or keep you safe for one try).
- **158 broad collar:** his father and mother are of Heliopolis; he is one of those set free when Geb looks on them. *Reward:* 75 (reaching Heliopolis). *Requirement:* entering the Hall (125), as a sign of where he belongs. Echoes 68, where the bolts of Geb open.
- **159 papyrus column:** the most obscure; spoken to a goddess at the door of the twin seats. Davis reads it as a small feldspar necklace passing through the gate of the double dwelling. *Tentative requirement:* the door of the Hall of Two Truths (125).
- **160 papyrus amulet held up by Thoth:** while it stays sound, the wearer stays sound; Thoth welcomes him, and his limbs won't be tied with cords. *Reward:* 161 (Thoth opening the doors, the next vignette) or Thoth in 94. *Use:* a life token: while it is unbroken, a lost try at the gates or mounds doesn't count.
- **Shape of it:** rewards come where the text points; requirements stay soft (a gate is optional). Since all six sit at the throat, they could hang on the avatar's neck as they're collected (one shared slot, a small redraw).
- [verify] 160's tall two-lobed shape doesn't look much like the papyrus amulet the text names. For 158–159 Davis has "necklaces" where Allen has a broad collar and a papyrus amulet.

### 161: Thoth opening the doors of the sky (pl. LXXVI, left) [seen]
- **Depicts:** **four ibis-headed Thoth figures** in two registers, each **pulling open a door** (the four winds).
- **Puzzle:** **open the four winds in order** using the compass. Each open door gives a gust that clears fog in one region or fills the sail from 38. A neat payoff of the compass from Act I.
- **Opening the door:** when the last door opens, the opening animation carries you through it into the Hall: it leads into the Weighing of the Heart (125).

### 162–165: Weird creatures (pl. LXXVII–LXXIX) [seen]

#### 162: Ihet cow (pl. LXXVII, right)
- **Depicts:** a **cow with a sun disc and plumes between her horns**, wearing a menat.
- **Use:** in the text, this cow gives warmth under the head of the deceased. Give the player **warmth/light** for the darkest stretch, the walk to the Hall. Visually a clean sprite; it can also stand in for an ending image.

#### 163–165: Weird creatures (pl. LXXVII–LXXIX)
- **163:**
  - a **wedjat eye with wings and human legs**
  - a **snake with human legs carrying a sun disc**
  - another **winged wedjat with legs**
- **164:** a **winged goddess with several heads** (three-faced) in the centre, flanked by **two dwarf-like ithyphallic figures with plumed or animal heads** raising their arms.
- **165:** a figure **with plumes on the shoulders**, and a **scarab-bodied, ithyphallic god with tall plumes** holding a flail.
- **Use as sprites:**
  - **Walking wedjat = the hint system.** When the player is stuck, a legged eye walks across the scene and stops at the next interaction. It's diegetic (*the eye sees all*) and needs no new art.
  - **Legged snake with sun disc = lantern bearer.** It walks ahead in dark scenes, lighting the way; the player follows it.
  - **164 three-faced goddess = a three-way choice.** Each face looks a different way and only one is "true"; choose by matching the face to the right companion figure.
  - **165 scarab-god = transformation of the heart.** A callback to the heart scarab; it can appear when the heart scarab from 30 is equipped.

---

## FINALE: 125. The Hall of Two Truths

### 125a/b: Negative Confession (pl. XLVI–XLIX) [seen]
- **Depicts:** a long text, then a **grid of 42 entries** (one per judge). Visually plain, as you noted.
- **Use:** don't make this a scene. Turn it into a **ledger UI**: 42 slots, each filled automatically by the evidence collected across the game (the councils of 18, the provisioning in 148, foes defeated, gates passed). The confession is the *summary* of your playthrough.

### 125d: Weighing of the Heart (pl. L) [seen]
- **Depicts:**
  - Reading right to left, entering through **lotus-topped columns**.
  - **The deceased** at the right, one hand raised to the face.
  - **Ma'at**, very tall, with the **feather on her head** and holding a long staff.
  - **The scale:**
    - a **baboon seated on top of the post**
    - **Horus** (falcon-headed) beside the post, reaching for the plumb
    - **Anubis** (jackal-headed) at the left pan, which holds a **small seated figure (Ma'at)**
    - the right pan holds the **heart, as a vessel**
    - a **small figure stands under the right pan, reaching up**
  - **Thoth** (ibis-headed), writing on a palette, facing Osiris; a tiny figure sits on a crook in front of him.
  - **Ammit** (the devourer) on a pedestal.
  - A heaped offering table topped with a **lotus bundle**; **the Four Sons of Horus** stand small above it.
  - **Osiris** enthroned in a shrine with crook and flail, with an **Imiut fetish (a skin on a pole)** beside him.
  - Above, the **frieze of the 42 judges**: tiny seated gods, **each with a different head**. At the right end, a small seated deceased adoring.
  - At the top, a cornice of uraei with feathers and ankhs, a winged central figure holding **two wedjat eyes**, and **baboons holding small scales** at both ends.
- **Final puzzle, in sequence:**
  1. **Enter between Ma'at's columns:** the deceased crop walks in only if you carry the ba and body reunited (89/92).
  2. **Present the heart:** place the heart vessel on the right pan and the heart scarab from 30 on it. Without the scarab the heart "speaks" and the scale wobbles. (The small figure under the pan can be the one who "pushes" the pan down if you skip a step.)
  3. **The 42 judges:** the frieze lights up judge by judge as the ledger is read. Each judge's head nods (yes) or turns (no) based on your evidence. This is the reactive feedback rule used on 42 tiny crops.
  4. **Balance:** Anubis adjusts the plumb while you place evidence on the feather side, and the baboon on the beam signals the balance (callback to the baboons at 126).
  5. **Thoth records:** the palette you got at 94 is handed back to Thoth to write the verdict.
  6. **Outcome:** balanced, and Horus leads you to Osiris. Unbalanced, and Ammit rises; retry with the evidence you missed.
- **Cross-reference payoffs already in the scene:** the Four Sons (148), baboons (16, 126), Thoth's palette (94), the wedjat (140), Ma'at's feather (160). The player recognizes nearly everything here, which makes it feel like an ending.

---

## Repetition / teaching map
| Concept | Taught in | Tested in | Final use |
|---|---|---|---|
| God heads | 17 | 144, 145 | 125 judges |
| Compass | 15–16 sun | 109, 137 | 148 oars, 151 |
| Sail/breath, water, bread | 38, 54–62, 57/59 | 110 farming | 148 cows |
| Forms | 77–88 | 144, 146, 149 | – |
| Ba/body | 89, 92 | gates needing flight | 125 entry |
| Heart scarab | 30 | – | 125 scale |
| Palette/journal | 94 | everywhere | 125 Thoth |
| Baboons as judges | 126 | – | 125 scale |

## Open questions (to research, not yet answered)
- **The strange creatures (162–165):** how might they be folded in? These are somewhat unusual spells. Check the research on them, see what scholars say, and give ideas from that.
- **Where they fit:** given all the planning here and in the Scene Atlas, where in the game would 162–165 fit?
- **The finale (125):** given all the planning so far, what are some ideas for a finale at 125?
- **Throughlines:** levels could be connected more with additional objects or throughlines. How, and how to make them meaningful, interesting and grounded in research?

## Still to verify
- **Exact count of the 18 councils.** I saw nine kneeling panels plus the Osiris closing scene. Check whether your "18a–j" labelling counts the closing scene as one of them.
- **Real answers from a translation (Allen or Faulkner):** the body-part and god pairs (42), the ferry part names (99), the guardian names at 144–146, and the amulet positions on the mummy (155–160).
