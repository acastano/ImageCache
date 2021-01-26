import UIKit
import ImageCache

class ViewController: UIViewController {
    @IBOutlet weak var imageView: NetworkImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let urlString = "https://images.pexels.com/photos/67636/rose-blue-flower-rose-blooms-67636.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260"
        imageView.load(with: urlString)
    }
}

