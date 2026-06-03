class CurvedLinesGenerator
{
  DataCurves data;
  PolylineGroup group = new PolylineGroup();

  CurvedLinesGenerator(DataCurves data)
  {
    this.data = data;
  }

  // ----------------------------------------------------------------
  // Build — rebuild spline from data.controlPoints, then offset a
  // dense polyline by i*spacing for each copy.
  // If data.islands is enabled, closed loops that form in concave
  // areas are captured and added to the group instead of discarded.
  // ----------------------------------------------------------------

  void build()
  {
    group.clear();
    if (data.controlPoints.size() < 2) return;

    // Build spline from current control points
    CatmullRomSpline spline = new CatmullRomSpline();
    for (PVector p : data.controlPoints) spline.addPoint(p);

    // Dense sampling: more steps → smoother offset curve
    int stepsPerSeg = max(6, data.sample_steps);
    Polyline basePoly = spline.toPolyline(stepsPerSeg);

    // Base curve (copy 0, no offset)
    group.add(basePoly);

    // Offset copies 1..count, each measured from the base
    for (int i = 1; i <= data.count; i++)
    {
      Polyline off = basePoly.offset(i * data.spacing);
      if (off == null || off.size() < 2) break;

      if (data.islands)
      {
        ArrayList<Polyline> extracted = new ArrayList<Polyline>();
        off = _removeSpikesExtractIslands(off, extracted);
        if (off == null || off.size() < 2) break;
        group.add(off);
        for (Polyline island : extracted) group.add(island);
      }
      else
      {
        off = off.removeSpikes();
        if (off == null || off.size() < 2) break;
        group.add(off);
      }
    }
  }

  // ----------------------------------------------------------------
  // Like Polyline.removeSpikes(), but captures each extracted loop
  // as a closed island polyline.
  // Strategy: among all crossings, take the one with LARGEST LOOP AREA.
  // The real concave pocket (triangle) has far more area than thin
  // spikes at V-notches. Area-based selection finds the correct loop.
  // Loops below MIN_ISLAND_AREA are silently trimmed (spikes/noise).
  // ----------------------------------------------------------------

  static final float MIN_ISLAND_AREA = 2000.0;  // px², tune to filter spikes

  Polyline _removeSpikesExtractIslands(Polyline src, ArrayList<Polyline> outIslands)
  {
    ArrayList<PVector> pts = new ArrayList<PVector>(src.points);

    boolean found = true;
    int safety = 0;
    int maxIter = pts.size() * 4;

    while (found && pts.size() >= 3 && safety++ < maxIter)
    {
      found = false;
      int n = pts.size();

      // Find the crossing whose extracted loop has the LARGEST area
      int bestI = -1, bestJ = -1;
      PVector bestIx = null;
      float bestArea = -1;

      for (int i = 0; i < n - 2; i++)
      {
        PVector a = pts.get(i), b = pts.get(i + 1);
        for (int j = i + 2; j < n - 1; j++)
        {
          PVector c = pts.get(j), e = pts.get(j + 1);
          PVector ix = _segIntersect(a, b, c, e);
          if (ix != null)
          {
            float area = abs(_loopSignedArea(pts, i, j, ix));
            if (area > bestArea)
            {
              bestI = i; bestJ = j; bestIx = ix; bestArea = area;
            }
          }
        }
      }

      if (bestI >= 0)
      {
        if (bestArea >= MIN_ISLAND_AREA)
        {
          // Real island: build closed curve, clean it, add to output
          Polyline island = new Polyline();
          island.addPoint(bestIx.copy());
          for (int k = bestI + 1; k <= bestJ; k++) island.addPoint(pts.get(k).copy());
          island.addPoint(bestIx.copy());
          island = island.removeSpikes();
          if (island != null && island.size() >= 4) outIslands.add(island);
        }
        // Remove loop from main polyline regardless (island or spike)
        pts.subList(bestI + 1, bestJ + 1).clear();
        pts.add(bestI + 1, bestIx);
        found = true;
      }
    }

    Polyline r = new Polyline();
    r.group_id = src.group_id;
    for (PVector p : pts) r.addPoint(p);
    return r;
  }

  // Shoelace signed area of loop: ix → pts[i+1..j] → ix
  private float _loopSignedArea(ArrayList<PVector> pts, int i, int j, PVector ix)
  {
    float area = 0;
    PVector prev = ix;
    for (int k = i + 1; k <= j; k++)
    {
      PVector curr = pts.get(k);
      area += (prev.x * curr.y - curr.x * prev.y);
      prev = curr;
    }
    area += (prev.x * ix.y - ix.x * prev.y);
    return area * 0.5;
  }

  // Segment intersection (strictly interior). Mirrors Polyline._segIntersect.
  private PVector _segIntersect(PVector a, PVector b, PVector c, PVector d)
  {
    float dab_x = b.x - a.x, dab_y = b.y - a.y;
    float dcd_x = d.x - c.x, dcd_y = d.y - c.y;
    float denom  = dab_x * dcd_y - dab_y * dcd_x;
    if (abs(denom) < 1e-6) return null;
    float t = ((c.x - a.x) * dcd_y - (c.y - a.y) * dcd_x) / denom;
    float u = ((c.x - a.x) * dab_y - (c.y - a.y) * dab_x) / denom;
    if (t > 1e-6 && t < 1 - 1e-6 && u > 1e-6 && u < 1 - 1e-6)
      return new PVector(a.x + t * dab_x, a.y + t * dab_y);
    return null;
  }

  // Draw handles from data.controlPoints (connected line + circles)
  void drawHandles()
  {
    noFill();
    // Connector line
    beginShape();
    for (PVector p : data.controlPoints) vertex(p.x, p.y);
    endShape();
    // Circles
    for (PVector p : data.controlPoints) ellipse(p.x, p.y, 8, 8);
  }
}
