## HudTwentyTwentyToTwentyTwentyTwo README

CSV translator to convert between the HUD HMIS
[2020](https://www.hudhdx.info/Resources/Vendors/HMIS%20CSV%20Specifications%20FY2020%20v1.8.pdf) and
[2022](https://www.hudhdx.info/Resources/Vendors/HMIS_CSV_Specifications_FY2022_v1.0.pdf) standards.


### Running The Translator

#### To Convert CSVs

From within the Rails console:

<pre>
HudTwentyTwentyToTwentyTwentyTwo::CsvTransformer.up(<i>source_dir</i>, <i>destination_dir</i>)
</pre>

#### To Convert DB

From the command line:

`rails driver:hud_twenty_twenty_to_twenty_twenty_two:migrate:up`
