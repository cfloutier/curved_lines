class DataCurves extends GenericData
{
  // Number of offset copies generated from the base curve
  int   count        = 10;
  // Distance in pixels between each successive curve
  float spacing      = 15.0;
  // Catmull-Rom sampling: steps per control-point segment
  int   sample_steps = 10;
  // Show control point handles
  boolean draw_handles = true;
  // Extract closed islands from concave loops during offset
  boolean islands = true;

  // Control points of the base spline (saved/loaded with settings)
  ArrayList<PVector> controlPoints = new ArrayList<PVector>();

  DataCurves()
  {
    super("Curves");
    _defaultPoints();
  }

  void _defaultPoints()
  {
    controlPoints.clear();
    controlPoints.add(new PVector(-120, -280));
    controlPoints.add(new PVector(-120, -120));
    controlPoints.add(new PVector( 120,  -60));
    controlPoints.add(new PVector( 120,   60));
    controlPoints.add(new PVector(-120,  120));
    controlPoints.add(new PVector(-120,  280));
  }

  // Override SaveJson to include controlPoints array
  JSONObject SaveJson()
  {
    JSONObject json = super.SaveJson();
    JSONArray pts = new JSONArray();
    for (int i = 0; i < controlPoints.size(); i++)
    {
      JSONObject pt = new JSONObject();
      pt.setFloat("x", controlPoints.get(i).x);
      pt.setFloat("y", controlPoints.get(i).y);
      pts.setJSONObject(i, pt);
    }
    json.setJSONArray("controlPoints", pts);
    return json;
  }

  // Override LoadJson to restore controlPoints array
  void LoadJson(JSONObject json)
  {
    super.LoadJson(json);
    if (json == null) return;
    JSONArray pts = json.getJSONArray("controlPoints");
    if (pts != null && pts.size() >= 2)
    {
      controlPoints.clear();
      for (int i = 0; i < pts.size(); i++)
      {
        JSONObject pt = pts.getJSONObject(i);
        controlPoints.add(new PVector(pt.getFloat("x"), pt.getFloat("y")));
      }
    }
  }
}

class CurvesGUI extends GUIPanel
{
  // "curves" — not "data" — to avoid shadowing the global sketch variable
  DataCurves curves;

  Slider count;
  Slider spacing;
  Slider sample_steps;
  Toggle draw_handles;
  Toggle islands;

  // Drag state
  int     dragIndex = -1;
  PVector lastMouse = null;

  CurvesGUI(DataCurves d)
  {
    super("Curves", d);
    this.curves = d;
  }

  void setupControls()
  {
    super.Init();

    count        = addIntSlider("count",        "Count",        1,   50);
    spacing      = addSlider   ("spacing",      "Spacing",      1,  200);
    nextLine();
    sample_steps = addIntSlider("sample_steps", "Sample Steps", 2,   30);
    nextLine();
    draw_handles = addToggle("draw_handles", "Handles");
    islands    = addToggle("islands",     "Islands");
  }

  void setGUIValues()
  {
    count.setValue(curves.count);
    spacing.setValue(curves.spacing);
    sample_steps.setValue(curves.sample_steps);
    draw_handles.setValue(curves.draw_handles ? 1 : 0);
    islands.setValue(curves.islands ? 1 : 0);
  }

  // Convert screen coords -> world coords (accounts for translate+scale in start_draw)
  // "data" here refers to the global CurvedLinesData from the sketch
  PVector mouseToWorld()
  {
    float s = data.page.global_scale;
    return new PVector((mouseX - width / 2.0) / s,
                       (mouseY - height / 2.0) / s);
  }

  boolean mousePressed()
  {
    if (!curves.draw_handles) return false;

    PVector pos = mouseToWorld();
    float hitR  = 10.0 / data.page.global_scale;  // 10px hit radius in world space

    for (int i = 0; i < curves.controlPoints.size(); i++)
    {
      if (PVector.dist(curves.controlPoints.get(i), pos) < hitR)
      {
        dragIndex = i;
        lastMouse = pos;
        return true;
      }
    }
    return false;
  }

  void mouseDragged()
  {
    if (dragIndex < 0) return;

    PVector pos   = mouseToWorld();
    PVector delta = PVector.sub(pos, lastMouse);

    PVector pt = curves.controlPoints.get(dragIndex);
    pt.add(delta);  // in-place, no need to set()
    lastMouse = pos;

    curves.changed = true;  // triggers rebuild in draw()
  }

  void mouseReleased()
  {
    dragIndex = -1;
    lastMouse = null;
  }
}
