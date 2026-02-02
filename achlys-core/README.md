/*
 * ACHLYS - "The Mist of Death"
 * Version: Hybrid Core (Shadow/Neon) v1.2
 * Capabilities: Network (Hands), Graphics (Eyes - Optional), System (Voice)
 *
 * --- COMPILE INSTRUCTIONS ---
 *
 * 1. THE SHADOW (Red Team / Server / Headless):
 * Use this for stealth implants, servers, or systems without GPUs.
 * Command: gcc achlys.c -o achlys -lm
 *
 * 2. THE NEON (Cyberpunk OS / GUI / Games):
 * Use this for your graphical terminal and visual tools. Requires Raylib.
 * Command: gcc achlys.c -o achlys_gui -DENABLE_GRAPHICS -lraylib -lm
 */