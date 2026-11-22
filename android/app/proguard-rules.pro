# PdfBox-Android documents JPEG 2000 as an optional image decoder.
# ShieldGuard parses object structure without rendering images.
# JPXFilter guards the optional decoder using Class.forName and reports an IOException.
-dontwarn com.gemalto.jp2.JP2Decoder
