//  Copyright © 2018 JABT. All rights reserved.


import Cocoa
import Quartz

class PdfViewController: NSViewController {

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        pdfThumbnailView.backgroundColor = #colorLiteral(red: 0.9961728454, green: 0.9902502894, blue: 1, alpha: 0)
        pdfView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true

        if let url = Bundle.main.url(forResource: "5V Relay", withExtension: "pdf") {
            if let pdfDoc = PDFDocument(url: url) {
                pdfView.document = pdfDoc
            }
        }
    }

    override func viewWillAppear() {
        pdfThumbnailView.pdfView = pdfView
    }
}
