(let* ((localBitmap (new 'System.Drawing.Bitmap 100 100))
       (og (invoke-static 'System.Drawing.Graphics 'FromImage localBitmap))
       (evt (new 'System.Windows.Forms.PaintEventArgs og (new 'System.Drawing.Rectangle 0 0 100 100))))
  (invoke l1 'OnPaint evt))