//This file was auto-corrected by findeclaration.exe on 29/05/2012 15:03:05

// === MEMETIC ANOMALY ===
// =======================

/**
This life form is a form of parasite that can gain a certain level of control
over its host. Its player will share vision and hearing with the host, and it'll
be able to influence the host through various commands.
**/

// The maximum amount of points a meme can gather.
var/global/const/MAXIMUM_MEME_POINTS = 750


// === PARASITE ===
// ================

// a list of all the parasites in the mob
mob/living/carbon/var/list/parasites = list()

mob/living/parasite
	var/mob/living/carbon/human/host // the host that this parasite occupies

	Login()
		..()

		// make the client see through the host instead
		client.eye = host
		client.perspective = EYE_PERSPECTIVE
		sleeping = 0


mob/living/parasite/proc/enter_host(mob/living/carbon/host)
	// by default, parasites can't share a body with other life forms
	if(host.parasites.len > 0)
		return 0

	var/mob/living/carbon/human/old_host = src.host
	src.host = host
	src.loc = host
	host.parasites.Add(src)
	old_host.parasites.Remove(src)

	if(client) client.eye = host

	return 1

mob/living/parasite/proc/exit_host()
	src.host.parasites.Remove(src)
	src.host = null
	src.loc = null

	return 1


// === MEME ===
// ============
mob/living/parasite/meme/

// Memes use points for many actions
	var/meme_points = 100
	var/dormant = 0

// Memes have a list of indoctrinated hosts
	var/list/indoctrinated = list()

mob/living/parasite/meme/New()
	..()

	var/list/allowed_mob = list()

	for (var/mob/living/carbon/human/H as mob in world)
		if(H.client && istype(H) && !H.parasites.len)
			allowed_mob += H

	if(!allowed_mob.len)
		message_admins("Failed to find host for meme [src.key]. Aborting.")
		del(src)
		return

	var/newhost = pick(allowed_mob)
	src.enter_host(newhost)
	message_admins("[host]([host.ckey]) has become [src.key]'s host", 0)
	log_game("[src.key] is a meme.[host]([host.ckey]) has become [src.key]'s host")

//	ticker.mode.memes += src

mob/living/parasite/meme/Del()
	..()

	if(host)
		exit_host()

mob/living/parasite/meme/Life()
	..()

	if(client)
		if(blinded) client.eye = null
		else		client.eye = host

	if(!host) return

	// recover meme points slowly
	var/gain = 3
	if(dormant) gain = 9 // dormant recovers points faster

	meme_points = min(meme_points + gain, MAXIMUM_MEME_POINTS)

	// if there are sleep toxins in the host's body, that's bad
	if(host.reagents.has_reagent("stoxin"))
		src << "\red <b>Something in your host's blood makes you lose consciousness... you fade away...</b>"
		src.death()
		return
	// a host without brain is no good
	if(!host.mind)
		src << "\red <b>Your host has no mind... you fade away..</b>"
		src.death()
		return
	if(host.stat == 2)
		src << "\red <b>Your host has died... you fade away..</b>"
		src.death()
		return

	if(host.blinded && host.stat != 1) src.blinded = 1
	else 			 				   src.blinded = 0


mob/living/parasite/meme/death()
	// make sure the mob is on the actual map before gibbing
	if(host) src.loc = host.loc
	host.parasites -= src
	src.stat = 2
	..()
	message_admins("[src.key](MEME) is die. Last host: [src.host]([src.host.ckey])", 0)
	log_game("[src.key](MEME) is die. Last host: [src.host]([src.host.ckey])")
	del src

// When a meme speaks, it speaks through its host
mob/living/parasite/meme/say(message as text)
	if(dormant)
		usr << "\red You're dormant!"
		return
	if(!host)
		usr << "\red You can't speak without host!"
		return

	log_game("[src.key](MEME) ([src.host]([src.host.ckey])) say: [message]")

	return host.say(message, 1)

// Same as speak, just with whisper
mob/living/parasite/meme/whisper(message as text)
	if(dormant)
		usr << "\red You're dormant!"
		return
	if(!host)
		usr << "\red You can't speak without host!"
		return

	log_game("[src.key](MEME) ([src.host]([src.host.ckey])) whisper: [message]")

	return host.whisper(message)

// Make the host do things
mob/living/parasite/meme/me_verb(message as text)
	set name = "Me"
	if(dormant)
		usr << "\red You're dormant!"
		return

	if(!host)
		usr << "\red You can't emote without host!"
		return
	message = sanitize_uni(message)
	log_game("[src.key](MEME) ([src.host]([src.host.ckey])) emote: [message]")
	return host.emote("me", 1, message)

// A meme understands everything their host understands
mob/living/parasite/meme/say_understands(mob/other)
	if(!host) return 0

	return host.say_understands(other)

// Try to use amount points, return 1 if successful
mob/living/parasite/meme/proc/use_points(amount)
	if(dormant)
		usr << "\red You're dormant!"
		return
	if(src.meme_points < amount)
		src << "<b>* You don't have enough meme points(need [amount]).</b>"
		return 0

	src.meme_points -= round(amount)
	return 1

// Let the meme choose one of his indoctrinated mobs as target
mob/living/parasite/meme/proc/select_indoctrinated(var/title, var/message)
	var/list/candidates

	// Can only affect other mobs thant he host if not blinded
	if(blinded)
		candidates = list()
		src << "\red You are blinded, so you can not affect mobs other than your host."
	else
		candidates = indoctrinated.Copy()

	candidates.Add(src.host)

	var/mob/target = null
	if(candidates.len == 1)
		target = candidates[1]
	else
		var/selected

		var/list/text_candidates = list()
		var/list/map_text_to_mob = list()

		for(var/mob/living/carbon/human/M in candidates)
			text_candidates += M.real_name
			map_text_to_mob[M.real_name] = M

		selected = input(message,title) as null|anything in text_candidates
		if(!selected) return null

		target = map_text_to_mob[selected]

	return target


// A meme can make people hear things with the thought ability
mob/living/parasite/meme/verb/Thought()
	set category = "Meme"
	set name	 = "Thought(50)"
	set desc     = "Implants a thought into the target, making them think they heard someone talk."

	if(meme_points < 50)
		// just call use_points() to give the standard failure message
		use_points(50)
		return

	var/list/candidates = indoctrinated.Copy()
	if(!(src.host in candidates))
		candidates.Add(src.host)

	var/mob/target = select_indoctrinated("Thought", "Select a target which will hear your thought.")

	if(!target) return

	var/speaker = input("Select the voice in which you would like to make yourself heard.", "Voice") as null|text
	if(!speaker) return

	var/message = input("What would you like to say?", "Message") as null
	if(!message) return
	message = sanitize_uni(message)

	// Use the points at the end rather than the beginning, because the user might cancel
	if(!use_points(50)) return

	message = say_quote(message)
	var/rendered = "<span class='game say'><span class='name'>[speaker]</span> <span class='message'>[message]</span></span>"
	target.show_message(rendered)

	usr << "<i>You make [target] hear:</i> [rendered]"

	log_game("[src.key](MEME) ([src.host]([src.host.ckey])) make [target]([target.ckey]) hear: [rendered]")

// Mutes the host
mob/living/parasite/meme/verb/Mute()
	set category = "Meme"
	set name	 = "Mute(250)"
	set desc     = "Prevents your host from talking for a while."

	if(!src.host) return
//	if(!host.speech_allowed)
	if(host.silent)
		usr << "\red Your host already can't speak.."
		return
	if(!use_points(250)) return

	spawn
		// backup the host incase we switch hosts after using the verb
		var/mob/living/carbon/human/host = src.host

		host << "\red Your tongue feels numb.. You lose your ability to speak."
		usr << "\red Your host can't speak anymore."

		host.silent = 1200
//		host.speech_allowed = 0

		message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) mute his host [src.host]([src.host.ckey])", 0)
		log_game("[src.key](MEME) mute his host [src.host]([src.host.ckey])")

		sleep(1200)

		host.silent = 0
		host << "\red Your tongue has feeling again.."
		usr << "\red [host] can speak again."

// Makes the host unable to emote
mob/living/parasite/meme/verb/Paralyze()
	set category = "Meme"
	set name	 = "Paralyze(250)"
	set desc     = "Prevents your host from using emote for a while."

	if(!src.host) return
	if(host.weakened)
		usr << "\red Your host already paralyzed.."
		return
	if(!use_points(250)) return

	host << "\red Your body feels numb.. You lose your ability to use body language."
	usr << "\red Your host can't use body language anymore."

	host.weakened = 1200

	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) paralyze his host [src.host]([src.host.ckey])", 0)
	log_game("[src.key](MEME) paralyze his host [src.host]([src.host.ckey])")

	sleep(1200)

	host.weakened = 0
	host << "\red Your body has feeling again.."
	usr << "\red [host] can use body language again."

// Cause great agony with the host, used for conditioning the host
mob/living/parasite/meme/verb/Agony()
	set category = "Meme"
	set name	 = "Agony(200)"
	set desc     = "Causes significant pain in your host."

	if(!src.host) return
	if(!use_points(200)) return

	spawn
		// backup the host incase we switch hosts after using the verb
		var/mob/host = src.host

		host.paralysis = max(host.paralysis, 2)

		host.flash_weak_pain()
		host << "\red <font size=5>You feel excrutiating pain all over your body! It is so bad you can't think or articulate yourself properly..</font>"

		usr << "<b>You send a jolt of agonizing pain through [host], they should be unable to concentrate on anything else for half a minute.</b>"

		host.emote("scream")

		host.attack_log += "\[[time_stamp()]\] <font color='orange'>Pained by [src.key](MEME)</font>"
		message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) pain his host [src.host]([src.host.ckey])", 0)
		log_game("[src.key](MEME) pain his host [src.host]([src.host.ckey])")

		for(var/i=0, i<10, i++)
			host.stuttering = 2
			sleep(50)
			if(prob(80)) host.flash_weak_pain()
			if(prob(10)) host.paralysis = max(host.paralysis, 2)
			if(prob(15)) host.emote("twitch")
			else if(prob(15)) host.emote("scream")
			else if(prob(10)) host.emote("collapse")

			if(i == 10)
				host << "\red THE PAIN! AGHH, THE PAIN! MAKE IT STOP! ANYTHING TO MAKE IT STOP!"

		host << "\red The pain subsides.."

// Cause great joy with the host, used for conditioning the host
mob/living/parasite/meme/verb/Joy()
	set category = "Meme"
	set name	 = "Joy(200)"
	set desc     = "Causes significant joy in your host."

	if(!src.host) return
	if(!use_points(200)) return

	spawn
		var/mob/host = src.host
		host.druggy = max(host.druggy, 50)
		host.slurring = max(host.slurring, 10)

		usr << "<b>You stimulate [host.name]'s brain, injecting waves of endorphines and dopamine into the tissue. They should now forget all their worries, particularly relating to you, for around a minute."

		host << "\red You are feeling wonderful! Your head is numb and drowsy, and you can't help forgetting all the worries in the world."

		log_game("[src.key](MEME) injecting waves of endorphines and dopamine into host [src.host]([src.host.ckey])")

		while(host.druggy > 0)
			sleep(10)

		host << "\red You are feeling clear-headed again.."

// Cause the target to hallucinate.
mob/living/parasite/meme/verb/Hallucinate()
	set category = "Meme"
	set name	 = "Hallucinate(300)"
	set desc     = "Makes your host hallucinate, has a short delay."

	var/mob/target = select_indoctrinated("Hallucination", "Who should hallucinate?")

	if(!target) return
	if(!use_points(300)) return

	target:hallucination += 100

	usr << "<b>You make [target] hallucinate.</b>"

	host.attack_log += "\[[time_stamp()]\] <font color='orange'>Hallucinated by [src.key](MEME)</font>"
	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) make his host [src.host]([src.host.ckey]) hallucinate", 0)
	log_game("[src.key](MEME) make his host [src.host]([src.host.ckey]) hallucinate")

// Jump to a closeby target through a whisper
mob/living/parasite/meme/verb/SubtleJump(mob/living/carbon/human/target as mob in view(1,host) - usr - usr:host)
	set category = "Meme"
	set name	 = "Subtle Jump(350)"
	set desc     = "Move to a closeby human through a whisper."

	if(!istype(target, /mob/living/carbon/human) || !target.mind)
		src << "<b>You can't jump to this creature..</b>"
		return
	if(!(target in view(1, host)+src))
		src << "<b>The target is not close enough.</b>"
		return

	// Find out whether we can speak
	if (host.silent || (host.disabilities & 64))
		src << "<b>Your host can't speak..</b>"
		return

	for(var/mob/M in view(1, host))
		M.show_message("<B>[host]</B> whispers something incoherent.",2) // 2 stands for hearable message

	// Find out whether the target can hear
	if(target.disabilities & 32 || target.ear_deaf)
		src << "<b>Your target doesn't seem to hear you..</b>"
		return

	if(target.parasites.len > 0)
		src << "<b>Your target already is possessed by something..</b>"
		return

	if(!use_points(350)) return

	var/mob/living/carbon/human/old_host = src.host
	src.exit_host()
	src.enter_host(target)

	usr << "<b>You successfully jumped to [target]."
	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[target]'>JMP</A>) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Whisper)", 0)
	log_game("[src.key](MEME) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Whisper)")

// Jump to a distant target through a shout
mob/living/parasite/meme/verb/ObviousJump(mob/living/carbon/human/target as mob in view(host) - usr - usr:host)
	set category = "Meme"
	set name	 = "Obvious Jump(750)"
	set desc     = "Move to any mob in view through a shout."

	if(!istype(target, /mob/living/carbon/human) || !target.mind)
		src << "<b>You can't jump to this creature..</b>"
		return
	if(!(target in view(host)))
		src << "<b>The target is not close enough.</b>"
		return

	// Find out whether we can speak
	if (host.silent || (host.disabilities & 64))
		src << "<b>Your host can't speak..</b>"
		return

	for(var/mob/M in view(host)+src)
		M.show_message("<B>[host]</B> screams something incoherent!",2) // 2 stands for hearable message

	// Find out whether the target can hear
	if(target.disabilities & 32 || target.ear_deaf)
		src << "<b>Your target doesn't seem to hear you..</b>"
		return

	if(target.parasites.len > 0)
		src << "<b>Your target already is possessed by something..</b>"
		return

	if(!use_points(750)) return

	var/mob/living/carbon/human/old_host = src.host
	src.exit_host()
	src.enter_host(target)

	usr << "<b>You successfully jumped to [target]."
	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[target]'>JMP</A>) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Shout)", 0)
	log_game("[src.key](MEME) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Shout)")

// Jump to an attuned mob for free
mob/living/parasite/meme/verb/AttunedJump(mob/living/carbon/human/target as mob in view(host) - usr - usr:host)
	set category = "Meme"
	set name	 = "Attuned Jump(0)"
	set desc     = "Move to a mob in sight that you have already attuned."

	if(!istype(target, /mob/living/carbon/human) || !target.mind)
		src << "<b>You can't jump to this creature..</b>"
		return
	if(!(target in view(host)))
		src << "<b>You need to make eye-contact with the target.</b>"
		return
	if(!(target in indoctrinated))
		src << "<b>You need to attune the target first.</b>"
		return

	if(target.parasites.len > 0)
		src << "<b>Your target already is possessed by something..</b>"
		return

	var/mob/living/carbon/human/old_host = src.host
	src.exit_host()
	src.enter_host(target)

	usr << "<b>You successfully jumped to [target]."

	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[target]'>JMP</A>) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Attune)", 0)
	log_game("[src.key](MEME) has jumped from [old_host]([old_host.ckey]) to [target]([target.ckey])(Attune)")


// ATTUNE a mob, adding it to the indoctrinated list
mob/living/parasite/meme/verb/Attune()
	set category = "Meme"
	set name	 = "Attune(400)"
	set desc     = "Change the host's brain structure, making it easier for you to manipulate him."

	if(host in src.indoctrinated)
		usr << "<b>You have already attuned this host.</b>"
		return

	if(!host) return
	if(!use_points(400)) return

	src.indoctrinated.Add(host)

	usr << "<b>You successfully indoctrinated [host]."
	host << "\red Your head feels a bit roomier.."

	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) has attuned [src.host]([src.host.ckey])", 0)
	log_game("[src.key](MEME) has attuned [src.host]([src.host.ckey])")

// Enables the mob to take a lot more damage
mob/living/parasite/meme/verb/Analgesic()
	set category = "Meme"
	set name	 = "Analgesic(500)"
	set desc     = "Combat drug that the host to move normally, even under life-threatening pain."

	if(!host) return
	if(!(host in indoctrinated))
		usr << "\red You need to attune the host first."
		return
	if(!use_points(500)) return

	usr << "<b>You inject drugs into [host]."
	host << "\red You feel your body strengthen and your pain subside.."
	host.analgesic = 60

	message_admins("[src.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) inject analgesic into [src.host]([src.host.ckey])", 0)
	log_game("[src.key](MEME) inject analgesic into [src.host]([src.host.ckey])")

	while(host.analgesic > 0)
		sleep(10)
	host << "\red The dizziness wears off, and you can feel pain again.."


mob/proc/clearHUD()
	if(client) client.screen.Cut()

// Take control of the mob
mob/living/parasite/meme/verb/Possession()
	set category = "Meme"
	set name	 = "Possession(500)"
	set desc     = "Take direct control of the host for a while."

	if(!host) return
	if(!(host in indoctrinated))
		usr << "\red You need to attune the host first."
		return
	if(!use_points(500)) return

	usr << "<b>You take control of [host]!</b>"
	host << "\red Everything goes black.."

	spawn
		var/mob/dummy = new()
		dummy.loc = 0
		dummy.sight = BLIND

		var/datum/mind/host_mind = host.mind
		var/datum/mind/meme_mind = src.mind

		host_mind.transfer_to(dummy)
		meme_mind.transfer_to(host)
		host_mind.current.clearHUD()
		host.update_body()

		dummy << "\blue You feel very drowsy.. Your eyelids become heavy..."

		host.attack_log += "\[[time_stamp()]\] <font color='orange'>Possessioned by [src.key](MEME)</font>"
		message_admins("[meme_mind.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) has taken possession of [host]([host_mind.key])", 0)
		log_game("[meme_mind.key](MEME) has taken possession of [host]([host_mind.key])")

		sleep(600)

		host.attack_log += "\[[time_stamp()]\] <font color='orange'>[src.key](MEME) has lost possession of host</font>"
		message_admins("[meme_mind.key](MEME)(<A HREF='?_src_=holder;adminplayerobservejump=\ref[src.host]'>JMP</A>) has lost possession of [host]([host_mind.key])", 0)
		log_game("[meme_mind.key](MEME) has lost possession of [host]([host_mind.key])")

		meme_mind.transfer_to(src)
		host_mind.transfer_to(host)
		meme_mind.current.clearHUD()
		host.update_body()
		src << "\red You lose control.."

		del dummy

// Enter dormant mode, increases meme point gain
mob/living/parasite/meme/verb/Dormant()
	set category = "Meme"
	set name	 = "Dormant(100)"
	set desc     = "Speed up point recharging, will force you to cease all actions until all points are recharged."

	if(!host) return
	if(!use_points(100)) return

	usr << "<b>You enter dormant mode.. You won't be able to take action until all your points have recharged.</b>"

	dormant = 1

	log_game("[src.key](MEME) activate Dormant")

	while(meme_points < MAXIMUM_MEME_POINTS)
		sleep(10)

	dormant = 0

	usr << "\red You have regained all points and exited dormant mode!"

	log_game("[src.key](MEME) have regained all points and exited dormant mode")

mob/living/parasite/meme/verb/Show_Points()
	set category = "Meme"

	usr << "<b>Meme Points: [src.meme_points]/[MAXIMUM_MEME_POINTS]</b>"

// Stat panel to show meme points, copypasted from alien
/mob/living/parasite/meme/Stat()
	..()

	statpanel("Status")
	if (client && client.holder)
		stat(null, "([x], [y], [z])")

	if (client && client.statpanel == "Status")
		stat(null, "Meme Points: [src.meme_points]")

// Game mode helpers, used for theft objectives
// --------------------------------------------
mob/living/parasite/check_contents_for(t)
	if(!host) return 0

	return host.check_contents_for(t)
