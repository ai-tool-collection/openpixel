"use client";

import { useState } from "react";
import Sprite from "@/components/Sprite";
import { art } from "@/lib/art";

const TABS = [
  {
    id: "sprites",
    label: "Sprites",
    caption: "32×32 treasure chest, 18×18 agent, 16×18 potion.",
    items: [
      { a: art.chest, scale: 7, label: "Pixel-art treasure chest" },
      { a: art.robot, scale: 8, label: "Robot agent sprite, blinking" },
      { a: art.potion, scale: 8, label: "Red potion with rising bubbles" },
    ],
  },
  {
    id: "voxels",
    label: "Voxel models",
    caption: "Tree island, mushroom house and the chest made 3D, turning in isometric view.",
    items: [
      { a: art.tree, scale: 2, label: "Voxel tree on a grass island, turning" },
      { a: art.mushroom, scale: 2, label: "Voxel mushroom house, turning" },
      { a: art.chest3d, scale: 2, label: "The treasure chest as a voxel model, turning" },
    ],
  },
  {
    id: "animation",
    label: "Animation",
    caption: "Frames, durations and onion skin, exported as GIFs or sprite sheets.",
    items: [
      { a: art.slime, scale: 9, label: "Slime bouncing, 6 frames" },
      { a: art.coin, scale: 9, label: "Coin spinning, 8 frames" },
      { a: art.campfire, scale: 9, label: "Campfire flickering, 4 frames" },
    ],
  },
] as const;

export default function Showcase() {
  const [tab, setTab] = useState<(typeof TABS)[number]["id"]>("sprites");
  const current = TABS.find((t) => t.id === tab)!;
  return (
    <div className="showcase">
      <div className="seg" role="tablist" aria-label="What you can make">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            role="tab"
            id={`tab-${t.id}`}
            aria-selected={t.id === tab}
            aria-controls="showcase-stage"
            onClick={() => setTab(t.id)}
          >
            {t.label}
          </button>
        ))}
      </div>
      <div className="stage" id="showcase-stage" role="tabpanel" aria-labelledby={`tab-${tab}`}>
        <div className="stage-row" key={tab}>
          {current.items.map((it) => (
            <Sprite key={it.label} art={it.a} scale={it.scale} label={it.label} />
          ))}
        </div>
        <p className="stage-caption">{current.caption}</p>
      </div>
    </div>
  );
}
