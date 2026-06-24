components {
  id: "ring"
  component: "/battle/rings/ring.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ring_001_32x32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/rings_32x32.atlas\"\n"
  "}\n"
  ""
}
