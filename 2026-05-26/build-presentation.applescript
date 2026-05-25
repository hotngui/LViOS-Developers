-- Build the May 2026 LViOS Developers Keynote deck.
-- Run with:   osascript /Users/joeyjarosz/LViOS-Developers/2026-05-26/build-presentation.applescript
--
-- Assumes /Users/joeyjarosz/LViOS-Developers/2026-05-26/Presentation.key already
-- exists as a copy of the January template. Opens it, replaces all 12 template
-- slides with 5 new content slides, and saves in place.

property kTargetPath : "/Users/joeyjarosz/LViOS-Developers/2026-05-26/Presentation.key"

-- Slide contents. Bullet lines are joined with `return` at insertion time.
property kTitleSlide : {title:"LViOS Developers", body:{"May 26, 2026", "Metal & SpriteKit"}}
property kMetalConceptSlide : {title:"When to use Metal", body:{¬
	"Maximum GPU performance and direct hardware control", ¬
	"Custom render pipelines, compute kernels, ML acceleration", ¬
	"3D graphics, advanced shaders, post-processing effects", ¬
	"Image processing where SwiftUI/UIKit drawing is too slow", ¬
	"Cross-platform: iOS, macOS, tvOS, visionOS"}}
property kSpriteKitConceptSlide : {title:"When to use SpriteKit", body:{¬
	"2D games and animated interfaces", ¬
	"Built-in physics, particle systems, and actions", ¬
	"Rapid prototyping — no shader code required", ¬
	"Node-based scene graph (SKNode, SKScene, SKSpriteNode)", ¬
	"Embeds in SwiftUI via SpriteView"}}
property kMetalExampleSlide : {title:"MetalExample", body:{¬
	"Three tabs demonstrating different Metal techniques", ¬
	"Tab 1: Custom render pipeline with MSL shaders", ¬
	"Tab 2: SwiftUI .colorEffect with stitchable Metal fragments", ¬
	"Tab 3: Compute kernels — grayscale, blur, edge detection", ¬
	"iOS 26, Swift 6.2, Swift Testing"}}
property kSpritePongSlide : {title:"SpritePong", body:{¬
	"Classic one-player Pong, portrait-only", ¬
	"SwiftUI shell hosting a single SKScene", ¬
	"@Observable GameState bridges UI and gameplay", ¬
	"Physics bodies for walls, paddle, and ball collisions", ¬
	"iOS 26.4, Swift Testing"}}

on joinBullets(bulletList)
	set acc to ""
	repeat with i from 1 to count of bulletList
		if i is 1 then
			set acc to item i of bulletList
		else
			set acc to acc & return & item i of bulletList
		end if
	end repeat
	return acc
end joinBullets

on lc(s)
	set out to ""
	repeat with c in s
		set asciiVal to id of (c as text)
		if asciiVal ≥ 65 and asciiVal ≤ 90 then
			set out to out & (character id (asciiVal + 32))
		else
			set out to out & (c as text)
		end if
	end repeat
	return out
end lc

on findMaster(masterNames, prefList, excludeWord)
	-- prefList is a list of substrings to try in priority order.
	-- excludeWord (or "") prevents matches containing that substring.
	repeat with pref in prefList
		set prefLower to lc(pref as text)
		repeat with mn in masterNames
			set mnLower to lc(mn as text)
			if mnLower contains prefLower then
				if excludeWord is "" or mnLower does not contain excludeWord then
					return mn as text
				end if
			end if
		end repeat
	end repeat
	return missing value
end findMaster

tell application id "com.apple.Keynote"
	activate
	open POSIX file kTargetPath

	-- Wait for the document to actually load.
	set waitCount to 0
	repeat until (count of documents) ≥ 1
		delay 0.2
		set waitCount to waitCount + 1
		if waitCount > 50 then error "Document never opened"
	end repeat
	set theDoc to document 1
	set waitCount to 0
	repeat until (count of slides of theDoc) ≥ 1
		delay 0.2
		set waitCount to waitCount + 1
		if waitCount > 50 then error "Document loaded with zero slides"
	end repeat

	set originalSlideCount to count of slides of theDoc
	set masterNames to name of every master slide of theDoc
	log "Available masters: " & (masterNames as text)

	-- Pick title-style master (no bullets) and bullets-style master.
	set titleMaster to my findMaster(masterNames, {"title & subtitle", "title - center", "title"}, "bullet")
	if titleMaster is missing value then set titleMaster to (name of master slide 1 of theDoc)
	set bulletsMaster to my findMaster(masterNames, {"title & bullets", "title, bullets", "bullet", "title & content"}, "")
	if bulletsMaster is missing value then set bulletsMaster to (name of master slide 1 of theDoc)

	log "Title master:   " & titleMaster
	log "Bullets master: " & bulletsMaster

	-- Add the 5 new slides at the end.
	set newSlides to {}
	set slideSpecs to {{titleMaster, kTitleSlide}, {bulletsMaster, kMetalConceptSlide}, {bulletsMaster, kSpriteKitConceptSlide}, {bulletsMaster, kMetalExampleSlide}, {bulletsMaster, kSpritePongSlide}}

	repeat with spec in slideSpecs
		set masterName to item 1 of spec
		set slideData to item 2 of spec
		set newSlide to make new slide at end of slides of theDoc with properties {base slide:master slide masterName of theDoc}

		-- Set title.
		try
			set object text of default title item of newSlide to (title of slideData)
		on error errMsg
			log "Could not set title on slide: " & errMsg
		end try

		-- Set body bullets.
		try
			set bodyText to my joinBullets(body of slideData)
			set object text of default body item of newSlide to bodyText
		on error errMsg
			log "Could not set body on slide '" & (title of slideData) & "': " & errMsg
		end try

		copy newSlide to end of newSlides
	end repeat

	-- Delete the original template slides (reverse iteration).
	repeat with i from originalSlideCount to 1 by -1
		delete slide i of theDoc
	end repeat

	save theDoc
	close theDoc saving no

	return "Done. Title master: " & titleMaster & " | Bullets master: " & bulletsMaster
end tell
