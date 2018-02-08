//  Copyright © 2018 JABT. All rights reserved.


import Cocoa
import Quartz

class PdfViewController: NSViewController {


    @IBOutlet weak var pdfView: PDFView! {
        didSet {
            pdfThumbnailView.pdfView = pdfView
            pdfView.displayMode = .singlePage
            pdfView.displayDirection = .horizontal
            pdfView.autoScales = true
            pdfView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        }
    }
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView! {
        didSet {
           pdfThumbnailView.backgroundColor = #colorLiteral(red: 0.9961728454, green: 0.9902502894, blue: 1, alpha: 0)
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = Bundle.main.url(forResource: "5V Relay", withExtension: "pdf") {
            if let pdfDoc = PDFDocument(url: url) {
                pdfView.document = pdfDoc
            }
        }
    }
}
