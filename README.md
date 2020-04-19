Image Caching iOS

To use the library 

import ImageCache

Implement a NetworkImageView prgrammatically or as an IBOutlet. NetworkImageView is an subclass of UIImageView

@IBOutlet weak var imageView: NetworkImageView!

to load the image pass the url as a string, the string is an optional in case the you are using a table or something that recycles if one item of the list doesn't a url pass nil 

imageView.load(with: urlString, placeholder: nil)
