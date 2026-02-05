// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later

#include "gamedef.h"
#include "nodedef.h"
#include "network/networkprotocol.h"
#include "tileanimation.h"

#include <catch.h>

#include <ios>
#include <sstream>

TEST_CASE("Node visual updates: modify texture names",
		"[nodevisual]")
{
	// Create a node def manager
	NodeDefManager *ndef = createNodeDefManager();
	
	// Register a test node
	ContentFeatures f;
	f.name = "test:stone";
	for (TileDef &tiledef : f.tiledef)
		tiledef.name = "default_stone.png";
	
	content_t id = ndef->set(f.name, f);
	REQUIRE(id != CONTENT_IGNORE);
	
	// Modify the node's tile texture using applyFunction
	ndef->applyFunction([&](ContentFeatures &cf) {
		if (cf.name == "test:stone") {
			cf.tiledef[0].name = "modified_texture.png";
		}
	});
	
	// Verify the change was applied
	const ContentFeatures &modified = ndef->get(id);
	CHECK(modified.tiledef[0].name == "modified_texture.png");
	CHECK(modified.tiledef[1].name == "default_stone.png"); // Others unchanged
	
	delete ndef;
}

TEST_CASE("Node visual updates: serialize after modification",
		"[nodevisual]")
{
	// Create a node def manager
	NodeDefManager *ndef = createNodeDefManager();
	
	// Register a test node
	ContentFeatures f;
	f.name = "test:dirt";
	for (TileDef &tiledef : f.tiledef)
		tiledef.name = "dirt.png";
	f.is_ground_content = true;
	
	content_t id = ndef->set(f.name, f);
	REQUIRE(id != CONTENT_IGNORE);
	
	// Modify the node's tile
	ndef->applyFunction([&](ContentFeatures &cf) {
		if (cf.name == "test:dirt") {
			cf.tiledef[0].name = "grass.png";
			cf.tiledef[0].has_color = true;
			cf.tiledef[0].color = video::SColor(255, 255, 0, 0); // Red
		}
	});
	
	// Serialize the modified node def manager
	std::ostringstream os(std::ios::binary);
	REQUIRE_NOTHROW(ndef->serialize(os, LATEST_PROTOCOL_VERSION));
	
	// Deserialize into a new manager
	NodeDefManager *ndef2 = createNodeDefManager();
	std::istringstream is(os.str(), std::ios::binary);
	REQUIRE_NOTHROW(ndef2->deSerialize(is, LATEST_PROTOCOL_VERSION));
	
	// Verify the modified node survived serialization
	content_t id2;
	bool found = ndef2->getId("test:dirt", id2);
	REQUIRE(found);
	
	const ContentFeatures &cf2 = ndef2->get(id2);
	CHECK(cf2.tiledef[0].name == "grass.png");
	CHECK(cf2.tiledef[0].has_color == true);
	CHECK(cf2.tiledef[0].color.getRed() == 255);
	
	delete ndef;
	delete ndef2;
}

TEST_CASE("Node visual updates: animation parameters",
		"[nodevisual]")
{
	// Create a node def manager
	NodeDefManager *ndef = createNodeDefManager();
	
	// Register a test node
	ContentFeatures f;
	f.name = "test:water";
	for (TileDef &tiledef : f.tiledef)
		tiledef.name = "water.png";
	
	content_t id = ndef->set(f.name, f);
	REQUIRE(id != CONTENT_IGNORE);
	
	// Add animation to the node
	ndef->applyFunction([&](ContentFeatures &cf) {
		if (cf.name == "test:water") {
			cf.tiledef[0].animation.type = TAT_VERTICAL_FRAMES;
			cf.tiledef[0].animation.vertical_frames.aspect_w = 16;
			cf.tiledef[0].animation.vertical_frames.aspect_h = 16;
			cf.tiledef[0].animation.vertical_frames.length = 2.0f;
		}
	});
	
	// Verify the animation was set
	const ContentFeatures &modified = ndef->get(id);
	CHECK(modified.tiledef[0].animation.type == TAT_VERTICAL_FRAMES);
	CHECK(modified.tiledef[0].animation.vertical_frames.aspect_w == 16);
	CHECK(modified.tiledef[0].animation.vertical_frames.length == 2.0f);
	
	delete ndef;
}

TEST_CASE("Node visual updates: edge cases",
		"[nodevisual]")
{
	NodeDefManager *ndef = createNodeDefManager();
	
	// Register a node
	ContentFeatures f;
	f.name = "test:edge_case";
	f.tiledef[0].name = "original.png";
	content_t id = ndef->set(f.name, f);
	
	// Test: Empty texture name should not crash
	REQUIRE_NOTHROW(ndef->applyFunction([&](ContentFeatures &cf) {
		if (cf.name == "test:edge_case") {
			cf.tiledef[0].name = ""; // Empty name
		}
	}));
	
	// Test: Very long texture name
	REQUIRE_NOTHROW(ndef->applyFunction([&](ContentFeatures &cf) {
		if (cf.name == "test:edge_case") {
			cf.tiledef[0].name = std::string(1000, 'x') + ".png";
		}
	}));
	
	// Test: Serialize after empty name doesn't crash
	std::ostringstream os(std::ios::binary);
	REQUIRE_NOTHROW(ndef->serialize(os, LATEST_PROTOCOL_VERSION));
	
	delete ndef;
}
