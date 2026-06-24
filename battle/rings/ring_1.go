components {
  id: "ring"
  component: "/battle/rings/ring.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ring_sample\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/rings.atlas\"\n"
  "}\n"
  ""
}
