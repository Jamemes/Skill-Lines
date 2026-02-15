Hooks:PostHook(SkillTreeManager, "save", "SkillLines.SkillTreeManager.save.PostHook", function(self, data)
	if data.SkillTreeManager then
		data.SkillTreeManager.skill_lines_upgrades = self._global.skill_lines_upgrades
	end
end)

Hooks:PreHook(SkillTreeManager, "load", "SkillLines.SkillTreeManager.load.PreHook", function(self, data)
	if data.SkillTreeManager and data.SkillTreeManager.skill_lines_upgrades then
		self._global.skill_lines_upgrades = data.SkillTreeManager.skill_lines_upgrades
		for upgrade, _ in pairs(data.SkillTreeManager.skill_lines_upgrades) do
			managers.upgrades:aquire(upgrade)
		end
	end
end)

Hooks:PostHook(SkillTreeManager, "_aquire_points", "SkillLines.SkillTreeManager._aquire_points.PostHook", function(self)
	for upgrade, _ in pairs(self._global.skill_lines_upgrades or {}) do
		managers.upgrades:unaquire(upgrade)
	end
	self._global.skill_lines_upgrades = nil
end)