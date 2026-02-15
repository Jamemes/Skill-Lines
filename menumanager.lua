Hooks:Add("LocalizationManagerPostInit", "SkillLines.LocalizationManagerPostInit", function()
	LocalizationManager:add_localized_strings({
		menu_skill_line_warn_message = "You have to reset all skills on the main skill trees.",
		menu_skill_lines = "Skill Lines",
		menu_insider_skill_line = "Insider",
		menu_control_skill_line = "Hostage Expert",
		menu_medic_skill_line = "Medic",
		menu_pistol_expert_skill_line = "Pistol Expert",
		menu_rifle_expert_skill_line = "Rifleman",
		menu_shotgun_expert_skill_line = "Shotgunner",
		menu_ammo_expert_skill_line = "Supplier",
		menu_armorer_skill_line = "Armorer",
		menu_discipline_skill_line = "Martial Artist",
		menu_hardware_expert_skill_line = "Hardware Specialist",
		menu_trip_mine_expert_skill_line = "Explosive Specialist",
		menu_sentry_expert_skill_line = "Sentry Expert",
		menu_burglar_skill_line = "Burglar",
		menu_hitman_skill_line = "Killer",
	})
end)

SkillButton = SkillButton or class(MenuGuiItem)
SkillButton._type = "SkillButton"

local function get_skills(tbl)
	for _, upgrade in pairs(tbl or {}) do
		if Global.upgrades_manager.aquired[upgrade] then
			return true
		end
	end
end

local function make_fine_text(text)
	local x, y, w, h = text:text_rect()

	if text:wrap() == true then
		text:set_h(h)
	else
		text:set_size(w, h)
	end

	text:set_position(math.round(text:x()), math.round(text:y()))
end

local function create_bg(panel, alpha)
	panel:rect({
		alpha = alpha or 0.5,
		layer = -2,
		color = Color.black
	})

	local blur = panel:bitmap({
		layer = -1,
		texture = "guis/textures/test_blur_df",
		render_template = "VertexColorTexturedBlur3D",
		w = panel:panel():w(),
		h = panel:panel():h()
	})

	local function func(o)
		local start_blur = 0

		over(0.6, function (p)
			o:set_alpha(math.lerp(start_blur, 1, p))
		end)
	end

	blur:animate(func)

	BoxGuiObject:new(panel, {
		sides = {
			1,
			1,
			1,
			1
		}
	})
end

function SkillButton:upgrades_aquired(skill_id)
	local aquired = {}
	local skill = tweak_data.skilltree.skills[skill_id]
	local previous_skill = tweak_data.skilltree.skills[self._first_skill]
	local previous_upgraded = self._last_skill == self._skill_id and true or get_skills(previous_skill and previous_skill[1] and previous_skill[1].upgrades)
	aquired.unlocked = self._first_skill == self._skill_id or previous_upgraded
	aquired.basic = get_skills(skill and skill[1] and skill[1].upgrades)
	aquired.aced = get_skills(skill and skill[2] and skill[2].upgrades)

	return aquired
end

function SkillButton:aquire_upgrades(skill_id, tier, aquire, mute)
	local skill = tweak_data.skilltree.skills[skill_id]
	if skill and tier then
		for _, upgrade in pairs(skill[tier].upgrades or {}) do
			if not aquire then
				managers.upgrades:unaquire(upgrade)
				Global.skilltree_manager.skill_lines_upgrades[upgrade] = nil
			else
				managers.upgrades:aquire(upgrade)
				Global.skilltree_manager.skill_lines_upgrades[upgrade] = true
			end
		end
		self._aquired = self:upgrades_aquired(skill_id)

		if aquire then
			SimpleGUIEffectSpewer.skill_up(self._bitmap:center_x(), self._bitmap:center_y(), self._panel)
		end

		if not mute then
			managers.menu_component:post_event("menu_skill_investment")
		end
	end
end

function SkillButton:flash()
	local function flash_anim(panel)
		local si_color = (self._aquired.basic and tweak_data.screen_colors.text) or (not self._aquired.unlocked and tweak_data.screen_colors.item_stage_2:with_alpha(0.15)) or tweak_data.screen_colors.item_stage_2
		local s = 0

		over(0.5, function (t)
			s = math.min(1, math.sin(t * 180) * 2)

			self._bitmap:set_color(math.lerp(si_color, tweak_data.screen_colors.important_1, s))
		end)
		self._bitmap:set_color(si_color)
	end

	self._bitmap:stop()
	self._bitmap:animate(flash_anim)
	managers.menu_component:post_event("menu_error")
end

function SkillButton:init(parent, params)
	self._w = 0.35
	self._line = params.line
	self._skill_id = tweak_data.skilltree.skill_lines[params.line].line[params.skill]
	self._first_skill = tweak_data.skilltree.skill_lines[params.line].line[1]
	self._last_skill = tweak_data.skilltree.skill_lines[params.line].line.last_skill
	self._previous_skill = params.skill ~= "last_skill" and tweak_data.skilltree.skill_lines[params.line].line[params.skill - 1]
	self._color = tweak_data.screen_colors.button_stage_3
	self._selected_color = tweak_data.screen_colors.button_stage_2
	self._links = {}
	self._panel = parent:panel({
		layer = 1000,
		w = parent:w(),
		h = parent:h()
	})

	self._info = tweak_data.skilltree.skills[self._skill_id]
	if self._info then
		self._info.name = self._skill_id
	end

	self._bitmap = self._panel:bitmap({
		texture = "guis/textures/pd2/skilltree/icons_atlas",
		name = "state_image",
		layer = 1,
		h = 48,
		w = 48,
		texture_rect = {
			self._info and self._info.icon_xy[1] * 64,
			self._info and self._info.icon_xy[2] * 64,
			64,
			64
		},
	})
	self._bitmap:set_center(self._panel:center_x(), self._panel:center_y())

	self._ace_icon = self._panel:bitmap({
		texture = "guis/textures/pd2/skilltree/ace",
		name = "state_indicator",
		h = 32,
		w = 32,
		alpha = 0,
		layer = 0,
	})
	self._ace_icon:set_rightbottom(self._panel:right(), self._panel:bottom())

	self._highlight = self._panel:rect({
		blend_mode = "add",
		alpha = 0.2,
		valign = "scale",
		halign = "scale",
		layer = 10,
		color = self._color
	})
	self:set_callback(function(button, allowed)
		if button == Idstring("0") then
			if self._aquired.unlocked and allowed then
				if not self._aquired.basic then
					self:aquire_upgrades(self._skill_id, 1, true)
				elseif self._aquired.basic and not self._aquired.aced then
					self:aquire_upgrades(self._skill_id, 2, true)
				end
			else
				self:flash()
			end
		elseif button == Idstring("1") then
			local line = tweak_data.skilltree.skill_lines[params.line].line
			if self._aquired.basic and self._aquired.aced then
				self:aquire_upgrades(self._skill_id, 2)
			elseif self._aquired.basic then
				self:aquire_upgrades(self._skill_id, 1)
			end

			if self._first_skill == self._skill_id and not self:upgrades_aquired(self._skill_id).basic and params.skill ~= "last_skill" then
				for i = 1, #line do
					if i > params.skill then
						self:aquire_upgrades(line[i], 1, nil, true)
						self:aquire_upgrades(line[i], 2, nil, true)
					end
				end
			end
		end

		self:refresh()
	end)

	self:refresh()
end

function SkillButton:refresh()
	self._aquired = self:upgrades_aquired(self._skill_id)
	self._highlight:set_visible(self:is_selected())
	self._highlight:set_color(self:is_selected() and self._selected_color or self._color)
	self._bitmap:set_color((self._aquired.basic and tweak_data.screen_colors.text) or (not self._aquired.unlocked and tweak_data.screen_colors.item_stage_2:with_alpha(0.15)) or tweak_data.screen_colors.item_stage_2)
	self._ace_icon:set_alpha(self._aquired.aced and 1 or 0)
end

function SkillButton:skill_unlocked()
	return self._panel
end

function SkillButton:panel()
	return self._panel
end

function SkillButton:inside(x, y)
	return self._panel:inside(x, y)
end

function SkillButton:callback()
	return self._callback
end

function SkillButton:set_callback(clbk)
	self._callback = clbk
end

function SkillButton:set_button(btn)
	self._btn = btn
end

function SkillButton:get_link(dir)
	return self._links[dir]
end

function SkillButton:set_link(dir, item)
	self._links[dir] = item
end

function SkillButton:update(t, dt)
end

SkillLinesComponent = SkillLinesComponent or class(MenuGuiComponentGeneric)

local padding = 10
function SkillLinesComponent:init(ws, fullscreen_ws, node)
	self._ws = ws
	self._fullscreen_ws = fullscreen_ws
	self._init_layer = self._ws:panel():layer()
	self._buttons = {}
	
	if managers.skilltree:trees_unlocked() ~= 0 then
		self._warn = ws:panel():panel({
			layer = 51,
			x = padding,
			y = padding,
			w = 500,
			h = 50,
		})
		create_bg(self._warn, 0.75)
		self._warn:set_center(ws:panel():center_x(), ws:panel():center_y())
			
		local message = self._warn:text({
			text = managers.localization:text("menu_skill_line_warn_message"),
			font_size = tweak_data.menu.pd2_large_font_size / 2,
			font = tweak_data.menu.pd2_large_font,
			color = tweak_data.screen_colors.text
		})
		make_fine_text(message)
		message:set_center(self._warn:w() / 2, self._warn:h() / 2)

		return
	end

	Global.skilltree_manager.skill_lines_upgrades = Global.skilltree_manager.skill_lines_upgrades or {}
	self.MAX_POINTS = math.floor(managers.experience:current_level() / 3.5)

	self:_setup()
end

function SkillLinesComponent:close()
	if alive(self._warn) then
		self._ws:panel():remove(self._warn)
	end

	if alive(self._panel) then
		self._ws:panel():remove(self._panel)
	end

	if alive(self._text_header) then
		self._ws:panel():remove(self._text_header)
	end

	if alive(self._points_counter) then
		self._ws:panel():remove(self._points_counter)
	end
end

function SkillLinesComponent:_setup()
	local parent = self._ws:panel()

	if alive(self._panel) then
		parent:remove(self._panel)
	end

	self._panel = self._ws:panel():panel({
		layer = 51
	})

	self._panel:set_h(580)
	self._panel:set_center_x(parent:center_x())
	self._panel:set_center_y(parent:center_y())

	self._text_header = self._ws:panel():text({
		vertical = "top",
		align = "left",
		layer = 51,
		text = "Skills",
		font_size = tweak_data.menu.pd2_large_font_size,
		font = tweak_data.menu.pd2_large_font,
		color = tweak_data.screen_colors.text
	})
	
	self._points_counter = self._ws:panel():text({
		layer = 51,
		text = "",
		font_size = tweak_data.menu.pd2_large_font_size / 2,
		font = tweak_data.menu.pd2_large_font,
		color = tweak_data.screen_colors.text
	})

	local x, y, w, h = self._text_header:text_rect()

	self._text_header:set_size(self._panel:w(), h)
	self._text_header:set_left(self._panel:left())
	self._text_header:set_bottom(self._panel:top())
	
	self._tweaks_list = self._tweaks_list or tweak_data
	self:_create_list_panel()
	self:_create_info_panel()
end

function SkillLinesComponent:mouse_wheel_up(x, y)
	local function scroll_up(scroll)
		if self[scroll] then
			return self[scroll]:scroll(x, y, 1)
		end
	end
	scroll_up("_list_scroll")
	scroll_up("_info_scroll")
end

function SkillLinesComponent:mouse_wheel_down(x, y)
	local function scroll_down(scroll)
		if self[scroll] then
			return self[scroll]:scroll(x, y, -1)
		end
	end
	scroll_down("_list_scroll")
	scroll_down("_info_scroll")
end

function SkillLinesComponent:confirm_pressed()
	if self._selected_item and self._selected_item:callback() then
		self._selected_item:callback()()
	end
end

function SkillLinesComponent:update_info_list(info)
	self._info_scroll:canvas():clear()
	local bitmap = self._info_scroll:canvas():bitmap({
		x = 15,
		y = 15,
		h = 64,
		w = 64,
		texture = "guis/textures/pd2/skilltree/icons_atlas",
		name = "state_image",
		layer = 1,
		texture_rect = {
			info and info.icon_xy[1] * 64,
			info and info.icon_xy[2] * 64,
			64,
			64
		}
	})

	local skill_name = self._info_scroll:canvas():text({
		text = managers.localization:text(info and info.name_id),
		layer = 3,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		color = tweak_data.screen_colors.text,
	})
	make_fine_text(skill_name)
	skill_name:set_lefttop(bitmap:right() + 10, 20)

	local editable_stats = info and tweak_data.upgrades.skill_descs[info.name] or {}
	editable_stats.basic = " "
	editable_stats.pro = " "

	local text = managers.localization:text(info and info.desc_id, editable_stats)
	local skill_text = self._info_scroll:canvas():text({
		word_wrap = true,
		name = "skill_text",
		vertical = "center",
		wrap = true,
		align = "left",
		blend_mode = "add",
		text = "",
		layer = 3,
		font = tweak_data.menu.pd2_small_font,
		font_size = tweak_data.menu.pd2_small_font_size,
		color = tweak_data.screen_colors.text,
		x = 10,
		w = self._info_scroll:canvas():w() - 20
	})

	local text_dissected = utf8.characters(text)
	local idsp = Idstring("#")
	local start_ci = {}
	local end_ci = {}
	local first_ci = true

	for i, c in ipairs(text_dissected) do
		if Idstring(c) == idsp then
			local next_c = text_dissected[i + 1]

			if next_c and Idstring(next_c) == idsp then
				if first_ci then
					table.insert(start_ci, i)
				else
					table.insert(end_ci, i)
				end

				first_ci = not first_ci
			end
		end
	end

	if #start_ci == #end_ci then
		for i = 1, #start_ci do
			start_ci[i] = start_ci[i] - ((i - 1) * 4 + 1)
			end_ci[i] = end_ci[i] - (i * 4 - 1)
		end
	end

	text = string.gsub(text, "##", "")
	skill_text:set_text(text)
	skill_text:clear_range_color(1, utf8.len(text))

	if #start_ci ~= #end_ci then
		Application:error("SkillTreeGui: Not even amount of ##'s in skill description string!", #start_ci, #end_ci)
	else
		for i = 1, #start_ci do
			skill_text:set_range_color(start_ci[i], end_ci[i], tweak_data.screen_colors.resource)
		end
	end

	make_fine_text(skill_text)
	skill_text:set_top(bitmap:bottom() + 10)
	self._info_scroll:update_canvas_size()
end

function SkillLinesComponent:mouse_moved(o, x, y)
	if not managers.menu:is_pc_controller() then
		return
	end

	local used, pointer = nil
	self._selected_item = nil

	local function scroll_move_mouse(scroll)
		if self[scroll] then
			self[scroll]._over_scroll_bar = self[scroll]._scroll_bar:visible() and self[scroll]._scroll_bar:inside(x, y)
			self[scroll]._over_arrow_up = alive(self[scroll]:panel():child("scroll_up_indicator_arrow")) and self[scroll]:panel():child("scroll_up_indicator_arrow"):inside(x, y)
			self[scroll]._over_arrow_down = alive(self[scroll]:panel():child("scroll_down_indicator_arrow")) and self[scroll]:panel():child("scroll_down_indicator_arrow"):inside(x, y)
			self[scroll]._current_y = self[scroll]._current_y or y

			if self[scroll]:panel():inside(x, y) then
				used, pointer = self[scroll]:mouse_moved(nil, x, y)
			end
		end
	end

	scroll_move_mouse("_info_scroll")
	scroll_move_mouse("_list_scroll")

	for idx, btn in pairs(self._buttons) do
		btn:set_selected(btn:inside(x, y) and self._list_scroll:panel():inside(x, y))

		if btn:is_selected() then
			self:update_info_list(btn._info)

			self._selected_item = btn
			pointer = "link"
			used = true
		end
	end

	return used, pointer
end

function SkillLinesComponent:_points()
	local points = 0
	for _, btn in pairs(self._buttons) do
		points = points + (btn._aquired.basic and 1 or 0) + (btn._aquired.aced and 1 or 0)
	end

	return points
end

function SkillLinesComponent:mouse_pressed(o, button, x, y)
	local function scroll_mouse_pressed(scroll)
		if self[scroll] then
			if self[scroll]._over_scroll_bar then
				self[scroll]._grabbed_scroll_bar = true
				self[scroll]._current_y = y
				
				return true
			elseif self[scroll]._over_arrow_up then
				self[scroll]._pressing_arrow_up = true
				return true
			elseif self[scroll]._over_arrow_down then
				self[scroll]._pressing_arrow_down = true
				return true
			end
		end
	end

	scroll_mouse_pressed("_list_scroll")
	scroll_mouse_pressed("_info_scroll")

	for _, btn in pairs(self._buttons) do
		if btn:is_selected() and btn:callback() then
			btn:callback()(o, self:_points() < self.MAX_POINTS)
		
			for i = 1, btn._skills_amount do
				self._buttons[btn._line .. i]:refresh()
			end
			self._buttons[btn._line .. "last_skill"]:refresh()
			
			self._points_counter:set_text(string.format("(%s/%s)", self:_points(), self.MAX_POINTS))
			make_fine_text(self._points_counter)
			return true
		end
	end
end

function SkillLinesComponent:mouse_released(o, button, x, y)
	local function scroll_mouse_released(scroll)
		if self[scroll] then
			self[scroll]._grabbed_scroll_bar = false
			self[scroll]._pressing_arrow_down = false
			self[scroll]._pressing_arrow_up = false
		end
	end

	scroll_mouse_released("_list_scroll")
	scroll_mouse_released("_info_scroll")
end

function SkillLinesComponent:_close()
	managers.menu:close_menu("menu_main")
	managers.menu:open_menu("menu_main")
end

function SkillLinesComponent:update(t, dt)
	local cx, cy = managers.menu_component:get_right_controller_axis()

	if cy ~= 0 and self._list_scroll then
		self._list_scroll:perform_scroll(math.abs(cy * 500 * dt), math.sign(cy))
	end

	if cy ~= 0 and self._info_scroll then
		self._info_scroll:perform_scroll(math.abs(cy * 500 * dt), math.sign(cy))
	end

	for _, btn in pairs(self._buttons) do
		btn:update(t, dt)
	end
end

function SkillLinesComponent:_create_list_panel()
	self._buttons = {}
	if self._list_panel then
		self._list_panel:clear()
	end

	self._list_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = 800,
		h = self._panel:h()
	})

	self._list_scroll = ScrollablePanel:new(self._list_panel, "list_panel_scroll", {
		force_scroll_indicators = true,
		padding = 0
	})

	local count = 0
	local line_h = 120
	for line, skills in pairs(tweak_data.skilltree.skill_lines) do
		local skill_line_panel = self._list_scroll:canvas():panel({
			x = padding,
			y = padding + (line_h + 10) * count - padding,
			w = self._list_panel:w() - 30,
			h = line_h
		})
		create_bg(skill_line_panel)

		local line_name = skill_line_panel:text({
			x = 10,
			y = 10,
			layer = 1,
			text = managers.localization:text(skills.name),
			font_size = tweak_data.menu.pd2_small_font_size,
			font = tweak_data.menu.pd2_small_font,
		})
		make_fine_text(line_name)

		local row = 10
		for index, _ in ipairs(skills.line) do
			local skill_panel = skill_line_panel:panel({
				w = skill_line_panel:w() / 8,
				h = line_h - 45
			})
			create_bg(skill_panel)
			skill_panel:set_top(line_name:bottom() + 2)
			skill_panel:set_left(row)
		
			local skill_btn = SkillButton:new(skill_panel, {
				skill = index,
				line = line
			})
			
			skill_btn._skills_amount = #skills.line
			self._buttons[line .. index] = skill_btn

			row = row + skill_panel:w() + 10
		end

		local last_skill_panel = skill_line_panel:panel({
			w = skill_line_panel:w() / 8,
			h = line_h - 45
		})
		create_bg(last_skill_panel)
		last_skill_panel:set_righttop(skill_line_panel:w() - 10, 10)

		local last_skill = SkillButton:new(last_skill_panel, {
			skills_amount = #skills.line,
			skill = "last_skill",
			line = line
		})
		last_skill._skills_amount = #skills.line
		self._buttons[line .. "last_skill"] = last_skill

		count = count + 1
	end

	self._points_counter:set_text(string.format("(%s/%s)", self:_points(), self.MAX_POINTS))
	make_fine_text(self._points_counter)
	make_fine_text(self._text_header)
	self._points_counter:set_bottom(self._text_header:bottom() - 5)
	self._points_counter:set_left(self._text_header:right() + 10)

	self._list_scroll:set_canvas_size(nil, (line_h + padding) * count)
end

function SkillLinesComponent:_create_info_panel()
	if self._info_panel then
		self._info_panel:clear()
	end

	self._info_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() / 3.5,
		h = self._panel:h() / 1.3
	})
	self._info_panel:set_left(self._list_panel:right() + padding)
	create_bg(self._info_panel)

	self._info_scroll = ScrollablePanel:new(self._info_panel, "info_panel_scroll", {
		force_scroll_indicators = true,
		padding = 0
	})
end

Hooks:Add("CoreMenuData.LoadDataMenu", "SkillLinesComponent.CoreMenuData.LoadDataMenu", function(menu_id, menu)
	if menu_id == "start_menu" then
		local new_node = {
			_meta = "node",
			name = "skill_lines",
			menu_components = "open_skill_lines",
			back_callback = "save_progress",
			font_size = 24,
			no_item_parent = true,
			no_menu_wrapper = true,
			scene_state = menu_id == "start_menu" and "blackmarket_item" or nil,
			{
				_meta = "default_item",
				name = "back"
			}
		}
		table.insert(menu, new_node)
	end
end)

Hooks:Add("MenuManagerBuildCustomMenus", "SkillLinesComponent_populate_categories", function(menu_manager, nodes)
	MenuHelper:AddMenuItem(nodes.main, "skill_lines", "menu_skill_lines", "", "divider_test2", "after")
	MenuHelper:AddMenuItem(nodes.lobby, "skill_lines", "menu_skill_lines", "", "edit_game_settings", "after")
end)

MenuHelper:AddComponent("open_skill_lines", SkillLinesComponent)