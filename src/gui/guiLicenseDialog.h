// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2024 Luanti contributors

#pragma once

#include "modalMenu.h"
#include <string>

class ISimpleTextureSource;
class Client;

class GUILicenseDialog : public GUIModalMenu
{
public:
	GUILicenseDialog(gui::IGUIEnvironment *env, gui::IGUIElement *parent,
			s32 id, IMenuManager *menumgr, ISimpleTextureSource *tsrc,
			const std::string &license_text, Client *client);

	void regenerateGui(v2u32 screensize) override;
	void drawMenu() override;
	bool OnEvent(const SEvent &event) override;

protected:
	std::wstring getLabelByID(s32 id) override { return L""; }
	std::string getNameByID(s32 id) override { return ""; }

private:
	ISimpleTextureSource *m_tsrc;
	std::string m_license_text;
	Client *m_client;
};
