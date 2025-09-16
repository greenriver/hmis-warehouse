## HudTwentyTwentyFourToTwentyTwentySix README

CSV translator to convert between the HUD HMIS

[2024](https://files.hudexchange.info/resources/documents/HMIS-CSV-Format-Specifications-2024.pdf) standards (removed by HUD).
[2026](https://icfonline.sharepoint.com/:w:/r/sites/NHDAP/VendorHub/_layouts/15/Doc.aspx?sourcedoc=%7B999D4839-12E5-443C-9D5A-BDD9865FEE4A%7D&file=FY%202026%20HMIS%20CSV%20Specifications_Final_April%202025.docx&action=default&mobileredirect=true) standards (not yet released).

### Running The Translator

#### To Convert CSVs

From within the Rails console:

<pre>
HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(<i>source_dir</i>, <i>destination_dir</i>)
</pre>
