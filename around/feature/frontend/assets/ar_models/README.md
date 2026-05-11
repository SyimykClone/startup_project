# AR models

Place GLB models in this folder and reference them from Supabase through
the `poi.ar_model_asset` field.

Expected files for the current AR objects:

```text
assets/ar_models/il28.glb
assets/ar_models/burana.glb
```

The AR screen loads the model path from API data, not from hardcoded UI logic.
