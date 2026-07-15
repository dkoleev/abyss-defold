components {
  id: "card_tarot"
  component: "/battle_tarot/card_tarot_opt2.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_0_fool\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/cards_tarot.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "back_sprite"
  type: "sprite"
  data: "default_animation: \"Tarot Backsides_tile_0\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/cards_tarot.atlas\"\n"
  "}\n"
  ""
}
