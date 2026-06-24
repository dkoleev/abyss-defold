components {
  id: "ring"
  component: "/battle/rings/ring.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ring_006_64x64\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/rings_64x64.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.5
    y: 0.5
  }
}
