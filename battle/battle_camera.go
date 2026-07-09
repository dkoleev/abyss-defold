components {
  id: "script"
  component: "/orthographic/camera.script"
  properties {
    id: "zoom"
    value: "2.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "camera"
  type: "camera"
  data: "aspect_ratio: 0.0\n"
  "fov: 0.0\n"
  "near_z: -1.0\n"
  "far_z: 1.0\n"
  "orthographic_projection: 1\n"
  "orthographic_zoom: 1.8\n"
  "orthographic_mode: ORTHO_MODE_AUTO_FIT\n"
  ""
}
