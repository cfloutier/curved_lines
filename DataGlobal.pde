class CurvedLinesData extends DataGlobal
{
  Style style   = new Style();
  DataCurves curves = new DataCurves();

  CurvedLinesData()
  {
    addChapter(style);
    addChapter(curves);
  }

  void reset()
  {
    style.CopyFrom(new Style());
    curves.CopyFrom(new DataCurves());
  }
}
