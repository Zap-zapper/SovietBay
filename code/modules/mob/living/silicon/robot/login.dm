/mob/living/silicon/robot/Login()
	..()
	regenerate_icons()
	show_laws(0)

	switch(winget(usr, null, "mainwindow.macro"))
		if("hotkeymode" || "borghotkeymode")
			winset(src, null, "mainwindow.macro=borghotkeymode hotkey_toggle.is-checked=false input.focus=true input.background-color=#D3B5B5")
		else
			winset(src, null, "mainwindow.macro=borgmacro hotkey_toggle.is-checked=false input.focus=true input.background-color=#D3B5B5")

	return