// Catmull-Rom spline class
// Holds a list of control points and provides:
//   - smooth draw via Processing curveVertex()
//   - toPolyline() export for offset generation and SVG export

class CatmullRomSpline
{
  ArrayList<PVector> controlPoints = new ArrayList<PVector>();
  boolean closed = false;

  CatmullRomSpline() {}

  CatmullRomSpline(boolean closed)
  {
    this.closed = closed;
  }

  // ----------------------------------------------------------------
  // Control points management
  // ----------------------------------------------------------------

  void addPoint(PVector p)       { controlPoints.add(p.copy()); }
  void set(int i, PVector p)     { controlPoints.set(i, p.copy()); }
  void clear()                   { controlPoints.clear(); }
  int  size()                    { return controlPoints.size(); }
  PVector get(int i)             { return controlPoints.get(i); }

  // ----------------------------------------------------------------
  // Export to Polyline (dense sampling)
  // stepsPerSegment : number of interpolated points per control segment
  // ----------------------------------------------------------------

  Polyline toPolyline(int stepsPerSegment)
  {
    Polyline result = new Polyline();
    int n = controlPoints.size();
    if (n < 2) return result;

    int segCount = closed ? n : n - 1;

    for (int i = 0; i < segCount; i++)
    {
      PVector p0, p1, p2, p3;
      if (closed)
      {
        p0 = controlPoints.get((i - 1 + n) % n);
        p1 = controlPoints.get(i % n);
        p2 = controlPoints.get((i + 1) % n);
        p3 = controlPoints.get((i + 2) % n);
      }
      else
      {
        p0 = controlPoints.get(max(0,     i - 1));
        p1 = controlPoints.get(i);
        p2 = controlPoints.get(i + 1);
        p3 = controlPoints.get(min(n - 1, i + 2));
      }

      for (int s = 0; s < stepsPerSegment; s++)
      {
        float t = (float)s / stepsPerSegment;
        result.addPoint(_crPoint(p0, p1, p2, p3, t));
      }
    }

    // Close or add final point
    if (closed)
      result.addPoint(controlPoints.get(0).copy());
    else
      result.addPoint(controlPoints.get(n - 1).copy());

    return result;
  }

  // ----------------------------------------------------------------
  // Draw using Processing curveVertex() — smooth, no tessellation
  // ----------------------------------------------------------------

  void draw()
  {
    int n = controlPoints.size();
    if (n < 2) return;

    current_graphics.noFill();
    current_graphics.beginShape();

    // curveVertex needs phantom first and last points
    if (closed)
    {
      current_graphics.curveVertex(
        controlPoints.get(n - 1).x,
        controlPoints.get(n - 1).y);
    }
    else
    {
      current_graphics.curveVertex(
        controlPoints.get(0).x,
        controlPoints.get(0).y);
    }

    for (PVector p : controlPoints)
      current_graphics.curveVertex(p.x, p.y);

    if (closed)
    {
      current_graphics.curveVertex(controlPoints.get(0).x, controlPoints.get(0).y);
      current_graphics.curveVertex(controlPoints.get(1).x, controlPoints.get(1).y);
    }
    else
    {
      current_graphics.curveVertex(
        controlPoints.get(n - 1).x,
        controlPoints.get(n - 1).y);
    }

    current_graphics.endShape();
  }

  // Draw control points as small circles with connecting line
  void drawHandles(float radius)
  {
    int n = controlPoints.size();
    if (n == 0) return;

    // Connecting line between handles
    current_graphics.noFill();
    current_graphics.beginShape();
    for (PVector p : controlPoints)
      current_graphics.vertex(p.x, p.y);
    if (closed && n > 0)
      current_graphics.vertex(controlPoints.get(0).x, controlPoints.get(0).y);
    current_graphics.endShape();

    // Handle circles
    for (PVector p : controlPoints)
      current_graphics.ellipse(p.x, p.y, radius * 2, radius * 2);
  }

  // ----------------------------------------------------------------
  // Internal: Catmull-Rom interpolation at t in [0,1]
  // ----------------------------------------------------------------

  private PVector _crPoint(PVector p0, PVector p1, PVector p2, PVector p3, float t)
  {
    float t2 = t * t;
    float t3 = t2 * t;
    float x = 0.5 * ((2 * p1.x)
      + (-p0.x + p2.x) * t
      + ( 2*p0.x - 5*p1.x + 4*p2.x - p3.x) * t2
      + (-p0.x + 3*p1.x - 3*p2.x + p3.x) * t3);
    float y = 0.5 * ((2 * p1.y)
      + (-p0.y + p2.y) * t
      + ( 2*p0.y - 5*p1.y + 4*p2.y - p3.y) * t2
      + (-p0.y + 3*p1.y - 3*p2.y + p3.y) * t3);
    return new PVector(x, y);
  }
}
