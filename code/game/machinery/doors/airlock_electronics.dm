/obj/item/airlock_electronics
	name = "airlock electronics"
	icon = 'icons/obj/doors/door_assembly.dmi'
	icon_state = "door_electronics"
	w_class = 2.0 //It should be tiny! -Agouri
	matter = list(DEFAULT_WALL_MATERIAL = 50,"glass" = 50)
	req_access = list(access_engine)

	var/secure = 0 //if set, then wires will be randomized and bolts will drop if the door is broken
	var/list/conf_access = list()
	var/one_access = 0 //if set to 1, door would receive req_one_access instead of req_access
	var/last_configurator = null
	var/locked = 1


/obj/item/airlock_electronics/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if (usr.stat || usr.restrained() || (!ishuman(usr) && !istype(usr,/mob/living/silicon)))
		return
	if (href_list["close"])
		usr << browse(null, "window=airlock")
		return 1
	if (href_list["login"])
		if(istype(usr,/mob/living/silicon))
			src.locked = 0
			src.last_configurator = usr.name
		else
			var/obj/item/I = usr.get_active_hand()
			if (istype(I, /obj/item/radio/headset/pda))
				var/obj/item/radio/headset/pda/pda = I
				I = pda.id
			if (I && src.check_access(I))
				src.locked = 0
				src.last_configurator = I:registered_name
	if (locked)
		return
	if (href_list["logout"])
		locked = 1
	if (href_list["one_access"])
		one_access = !one_access
	if (href_list["access"])
		toggle_access(href_list["access"])
	attack_self(usr)
	return 1

/obj/item/airlock_electronics/attack_self(var/mob/user)
	if (!ishuman(user) && !istype(user,/mob/living/silicon/robot))
		return ..(user)
	var/t1 = text("<B>Access control</B><br>\n")
	if (last_configurator)
		t1 += "Operator: [last_configurator]<br>"
	if (locked)
		t1 += "<a href='?src=\ref[src];login=1'>Swipe ID</a><hr>"
	else
		t1 += "<a href='?src=\ref[src];logout=1'>Block</a><hr>"
		t1 += "Access requirement is set to "
		t1 += one_access ? "<a style='color: green' href='?src=\ref[src];one_access=1'>ONE</a><hr>" : "<a style='color: red' href='?src=\ref[src];one_access=1'>ALL</a><hr>"
		t1 += conf_access == null ? "<font color=red>All</font><br>" : "<a href='?src=\ref[src];access=all'>All</a><br>"
		t1 += "<br>"
		var/list/accesses = get_all_station_access()
		for (var/acc in accesses)
			var/aname = get_access_desc(acc)
			if (!conf_access || !conf_access.len || !(acc in conf_access))
				t1 += "<a href='?src=\ref[src];access=[acc]'>[aname]</a><br>"
			else if(one_access)
				t1 += "<a style='color: green' href='?src=\ref[src];access=[acc]'>[aname]</a><br>"
			else
				t1 += "<a style='color: red' href='?src=\ref[src];access=[acc]'>[aname]</a><br>"
	t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>\n", src)
	var/datum/browser/popup = new(user, "airlock_electronics","Airlock Electronics Configuration", 700, 500, src)
	popup.set_content(t1)
	popup.open()

/obj/item/airlock_electronics/proc/toggle_access(var/acc)
	if (acc == "all")
		conf_access = null
	else
		var/req = text2num(acc)
		if (conf_access == null)
			conf_access = list()
		if (!(req in conf_access))
			conf_access += req
		else
			conf_access -= req
			if (!conf_access.len)
				conf_access = null

/obj/item/airlock_electronics/secure
	name = "secure airlock electronics"
	desc = "designed to be somewhat more resistant to hacking than standard electronics."

	secure = 1
