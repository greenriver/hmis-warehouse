## HudTwentyTwentyTwoToTwentyTwentyFour README

CSV translator to convert between the HUD HMIS
[2022](https://www.hudhdx.info/Resources/Vendors/HMIS_CSV_Specifications_FY2022_v1.0.pdf) and.
[2024](https://files.hudexchange.info/resources/documents/HMIS-CSV-Format-Specifications-2024.pdf) standards.

### Running The Translator

#### To Convert CSVs

From within the Rails console:

<pre>
HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer.up(<i>source_dir</i>, <i>destination_dir</i>)
</pre>

#### To Convert DB

From the command line:

`rails driver:hud_twenty_twenty_two_to_twenty_twenty_four:migrate:up`
