// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2024 Luanti contributors

#include "guiLicenseDialog.h"
#include "guiButton.h"
#include "guiEditBoxWithScrollbar.h"
#include <IGUIEditBox.h>
#include <IGUIFont.h>
#include <IVideoDriver.h>
#include "client/client.h"
#include "gettext.h"

namespace {
	constexpr int ID_text    = 256;
	constexpr int ID_accept  = 257;
	constexpr int ID_decline = 258;
}

GUILicenseDialog::GUILicenseDialog(gui::IGUIEnvironment *env,
		gui::IGUIElement *parent, s32 id,
		IMenuManager *menumgr, ISimpleTextureSource *tsrc,
		const std::string &license_text, Client *client) :
	GUIModalMenu(env, parent, id, menumgr),
	m_tsrc(tsrc),
	m_license_text(license_text),
	m_client(client)
{
}

void GUILicenseDialog::regenerateGui(v2u32 screensize)
{
	removeAllChildren();

	ScalingInfo info = getScalingInfo(screensize, v2u32(700, 500));
	const float s = info.scale;
	DesiredRect = info.rect;
	recalculateAbsolutePosition(false);

	v2s32 size = DesiredRect.getSize();
	v2s32 topleft(20 * s, 0);

	// Title
	{
		core::rect<s32> rect(0, 0, size.X - 40 * s, 30 * s);
		rect += topleft + v2s32(0, 10 * s);
		gui::StaticText::add(Environment, wstrgettext("License Agreement"),
				rect, false, true, this, -1);
	}

	// License text box
	{
		core::rect<s32> rect(0, 0, size.X - 40 * s, size.Y - 100 * s);
		rect += topleft + v2s32(0, 50 * s);

		FontSpec fontspec(FONT_SIZE_UNSPECIFIED, FM_Mono, false, false);
		fontspec.allow_server_media = false;
		auto font = g_fontengine->getFont(fontspec);

		auto *e = new GUIEditBoxWithScrollBar(utf8_to_wide(m_license_text).c_str(),
				true, Environment, this, ID_text, rect, m_tsrc, false, true);
		e->setMultiLine(true);
		e->setWordWrap(true);
		e->setTextAlignment(gui::EGUIA_UPPERLEFT, gui::EGUIA_UPPERLEFT);
		e->setDrawBorder(true);
		e->setDrawBackground(true);
		e->setOverrideFont(font);
		e->drop(); // The parent (this) took ownership and incremented the refcount
	}

	s32 btn_y = size.Y - 45 * s;
	s32 btn_w = 120 * s;
	s32 btn_h = 35 * s;

	// Accept button
	{
		core::rect<s32> rect(0, 0, btn_w, btn_h);
		rect += v2s32(size.X / 2 - btn_w - 10 * s, btn_y);
		GUIButton::addButton(Environment, rect, m_tsrc, this, ID_accept,
				wstrgettext("Accept").c_str());
	}

	// Decline button
	{
		core::rect<s32> rect(0, 0, btn_w, btn_h);
		rect += v2s32(size.X / 2 + 10 * s, btn_y);
		GUIButton::addButton(Environment, rect, m_tsrc, this, ID_decline,
				wstrgettext("Decline").c_str());
	}
}

void GUILicenseDialog::drawMenu()
{
	gui::IGUISkin *skin = Environment->getSkin();
	if (!skin)
		return;
	video::IVideoDriver *driver = Environment->getVideoDriver();

	video::SColor bgcolor(140, 0, 0, 0);
	driver->draw2DRectangle(bgcolor, AbsoluteRect, &AbsoluteClippingRect);

	gui::IGUIElement::draw();
}

bool GUILicenseDialog::OnEvent(const SEvent &event)
{
	if (event.EventType == EET_KEY_INPUT_EVENT) {
		if (event.KeyInput.Key == KEY_ESCAPE && event.KeyInput.PressedDown) {
			// Escape acts as Decline
			quitMenu();
			// m_client will be notified by the game loop (license still pending)
			return true;
		}
	}

	if (event.EventType == EET_GUI_EVENT) {
		if (event.GUIEvent.EventType == gui::EGET_ELEMENT_FOCUS_LOST &&
				isVisible()) {
			if (!canTakeFocus(event.GUIEvent.Element)) {
				infostream << "GUILicenseDialog: Not allowing focus change."
					<< std::endl;
				return true;
			}
		}

		if (event.GUIEvent.EventType == gui::EGET_BUTTON_CLICKED) {
			switch (event.GUIEvent.Caller->getID()) {
			case ID_accept:
				m_client->acceptLicense();
				quitMenu();
				return true;
			case ID_decline:
				quitMenu();
				return true;
			}
		}
	}

	return Parent != nullptr && Parent->OnEvent(event);
}
