# the Matching Algorithm

This document explains how we find similar HUD client records which we might merge.

The basic idea is that we extract potential dimensions of similarity from these records -- same gender, similar age,
same race, similar name, etc. For each dimension we define a way of mapping a pair of values to a measure ("metric")
of similarity. Then we take a sample population and calculate two aggregate statistics over all pairs within this
population: the mean similarity within this population and the standard deviation.

Given these two values, we can calculate a z-score for a particular pair of individuals and a particular dimension.
This is the number of standard deviations off the mean these two are in their similarity in this dimension.

Each metric also has a weight which can be used to modify its influence in the final ranking. If this weight is
set to 0, the metric is not used for ranking. Otherwise, the greater the weight the greater the metric's influence
on the final ranking. This was the original idea of this property of metrics, at any rate. In practice we just leave
all metrics we have implemented with a weight of 1.

## Types of Metrics

Metrics vary according to the type of value they are comparing. In the end we want numbers. In principle a numeric
dimension like age would be the simplest to work with; however, we do not yet have any numeric dimensions. The
remaining dimensions all have values that are strings, like names or social security numbers, or members of some closed set
of values. The latter are called "multinomial" dimensions. In general, strings are compared by edit distance
similarity -- how many changes one would have to make in one string to turn it into the other; values from closed
sets are compared by identity -- are both individuals male? Both hispanic?

All similarity metrics resemble distance metrics: a higher number means they are *farther apart*, *less* similar.

### String Similarity

How we compare strings varies according to what the strings represent. If they represent human speech -- names, for
instance -- we want to compare how they sound. We want "thru" to be more similar to "through" than to "thrum", though
there are more letters changed between "thru" and "through" than between "thru" and "thrum". The basic mechanism
we use for this comparison is the [double-metaphone](https://en.wikipedia.org/wiki/Metaphone#Double_Metaphone) algorithm.
This normalizes a string into something representing its most distinctive phonetic qualities. For example, it converts
both "thru" and "through" into the pair "0R" and "TR", whereas it converts "thrum" into the pair "0RM" and "TRM".
So to compare two names we would convert each names into its list of double-metaphone representations, compare these
lists pairwise, and pick the lowest (Levenshtein distance)[https://en.wikipedia.org/wiki/Levenshtein_distance](see below)
between the two members of any of these pairs. For "through" and "thru" this would give us a similarity of 0;
for "thru" and "thrum", a similarity of 1.

For strings which represent something more like serial numbers, such as social security numbers, we just use the
Levenshtein distance. This is a count of the minimum number of character edits, additions, subtractions, or replacements,
to convert one string into another. The Levenshtein distance between "cat" and "dog" is 3; between "cat" and "cad"
is 1. Or, more usefully, the Levenshtein distance between "123-45-6789" and "223-45-6789" is 1.

### Multinomial Dimensions

For multinomial dimenions we might just return two values: 0 if they match and 1 otherwise. So, if both individuals
identify as white, their similarity in this dimenions would be 0. If they both identify as Pacific islander, they are
also both 0. But this would throw away useful information! There are a lot more people in the general population
who identify as white than who identify as Pacific islander. We would like to rank two people who are both Pacific
islanders as more likely to be a match than two people who are both white. So for multinomial values we weight
the value returned, in the case of a match, by the inverse of the frequency of that characteristic in the general
population. To prevent outlier populations from swamping other similarity measures, we cap this weight. The tuning
of this cap is a possible avenue to explore in improving the matching algorithm.

A particularly common variety of multinomial dimension is the binary dimension: female or not, e.g. This is still just
a multinomial property, though, just one with only two possible values. We handle these the same way as other
multinomial dimensions.

## Initializing

When starting on a new batch of data we must first initialize all the similarity metrics. That is, we need to calculate
a mean and standard deviation for each and, in the case of multinomials, we must determine the relative frequency of
each value and thus its usefulness in indicating dissimilarity. This can be done via

```ruby
SimilarityMetric::Initializer.new.run!
```

Multinomial statistics are determined by summing over *all* data.

Means and standard deviations are calculated by taking a random sample of the available data, by default, 500 records,
constructing all possible distinct pairs of distinct records -- so never (A, A) and (A, B) and (B, A) being considered
the same pair -- and calculating the statics for each metric over these pairs. For 500 records that is 500 * 499 / 2
pairs, or 124,750 data points. A particular metric won't have a defined value at every data point. 

## Selecting Candidates

### Merged Records

We merge records iteratively. We may find we have two John Smith records, so we merge them. Later, we find another John
Smith record. Now we want to merge it not with another single record but a cluster of records.

When we have a candidate to merge with a cluster, we calculate the scores of the candidate with each member of the cluster
and then merge these into a single set of scores by retaining the best score of each type.

This mechanism serves to fill in gaps, for one thing. If one record in the cluster has a first name but no last name and
another has a last name but no first, each metric provides a score for the final amalgamation. Whether this is the
best mechanism in a case where there is no gap is an issue that could use further exploration. The idea was that typos
and data errors are more likely to produce dissimilarity than similarity, so if you have to choose between two scores
it is safe to pick the better for this reason, but this we proceeded with this hypothesis without testing it rigorously.

### Score Amalgamation

To produce a single score for each candidate, we merge the various scores available, discarding undefined scores. The
merge mechanism is a weighted average of these scores. That is, we take each score, multiply it by its metric's weight,
and sum these. Then we divide this by the sum of the weights. In practice, though, this is just an average, because
we have not adjusted the weights. Since all the weights are the same, in fact, they are all 1, this amounts to summing
the scores and dividing by the number of scores.

### Zero Crossing

This is a mechanism we use to cull a candidate set: we calculate amalgamated scores for the candidates, rank them, and
calculate the "acceleration" of this score. That is, we treat each score as an offset in score space, a position.
The change in this position from candidate to candidate is a velocity in this space. The change in velocity from
candidate to candidate is acceleration. Where the acceleration crosses from negative to positive or vice versa defines
where the curvature of the score curve has inverted. We treat this as the edge of a score plateau. Experiment showed
that it was a useful place to cut the candidate list. In general, what we see is the score creeping up but decelerating
to a point, then turning and swooping up. It is the candidates in the upsweep that we discard.

## Experiments

In the `SimilarityMetric` there is an `Experiment` sub-module that provides module functions to facilitate divising and
testing new similarity metrics. Within this module are various classes:
- `SimilarityMetric::Experiment::Ranking`
- `SimilarityMetric::Experiment::ScoreHistogram`
- `SimilarityMetric::Experiment::MetricScoreHistogram`

These could stand to be documented further. They are the mechanism by which the various metrics in use, such as
`SimilarityMetric::Gender`, were developed. They facilitate seeing the range of values a particular metric
must deal with, its sparseness, etc.

## Suggestions for Further Improvement

Because we accrue data over time, and because the data may change over time, it would be good to re-initialize the
similarity metrics periodically, perhaps once a month, quarter, or year. This will improve the weighting of multinomial
metrics, for one thing, and make the training sample more representative.

This algorithm was originally designed around the constraint that we lacked any training data with which to make
a more intelligent algorithm, one that could learn from human judgment. However, we have since recorded human judgments. It
would be a fairly simple matter to feed these judgments together with the values returned from our similarity metrics
to a machine learning model. Our judgements are "accept" and "reject" or something similar. We would train a classifier
to assign a probability that a human would judge the pair acceptable, mergeable. We could then use the probabilities
returned to rank candidate pairs for presentation to a human judge. Or, if we find our model sufficiently accurate, we
could let it automatically merge candidates given a certain probability threshold.

Doing this would achieve a number of things:
1. Right now we treat all our metrics as equally useful. The classifier would infer their relative importance and assign
   them an appropriate weight.
2. Right now we treat all our metrics as independent, though there are likely some that are not independent. Treating metrics
   as independent which are not inflates the importance of these metrics. For example, if we simply used the same metric twice,
   this would in effect double the influence of one dimension of variation. An ML model could discover and account for these
   dependencies.
3. Right now the output of the matching algorithm is a mystery number without interpretation to human judges. A classifier (of
   the desired type) would give us a probability. *Note*: this could actually be dangerous, giving users a false confidence
   in the number and encouraging them to suspend their own judgment.

A simple classifier algorithm that could work for us would be logistic regression, also known as maximum entropy. Maximum
entropy classifiers do a good job of estimating probabilities, not merely assigning labels, and they are fairly efficient
to train. The [rumale](https://github.com/yoshoku/rumale) gem could provide a pure Ruby testbed (and can be combined with
various C libraries for a speed boost, such as libsvm, though this would be for support vector machines, not logistic
regression). I expect for our purposes this would be sufficient.

If we do this, we should continue re-initializing the similarity metrics on a schedule, since this will improve the metrics,
and the proposal is that we use these metrics to provide feature vectors we feed to the classifier. Periodically, as we
accumulate new human judgments, we should process the entire set of such judgments into labeled feature vectors we can then
use to train our classifier. Then we can use the classifier to generate probabilities that we use to rank the merge
candidates we present for human judgment.

Also, when we generate a new classifier we should use [n-fold cross validation](https://en.wikipedia.org/wiki/Cross-validation_(statistics)#k-fold_cross-validation)
to estimate the accuracy of the classifier. There are various metrics for classifier accuracy. The standards are precision
and recall. These are basically equivalent to measures of false positives and false negatives. A standard way to combine
these into one measure of accuracy is the [f-measure](https://en.wikipedia.org/wiki/F-score), the harmonic mean of precision
and recall. There are other measures, such as the [area under the ROC curve](https://en.wikipedia.org/wiki/Receiver_operating_characteristic),
but the f-measure is easy to calculate. If we generate an f-measure from n-fold cross validation every time we generate a
new classifier, we can monitor whether this process is succeeding. If not, we might consider a different classification
algorithm, or tinker with our feature set.

One thing we should avoid is feeding the classifier its own judgments as training data. This is unlikely to produce greater
accuracy.

Another concern is that we will be training the classifier not on all data it will face but the data our initial ranking
mechanism presents to users. This means that our training set, at least initially, may be dissimilar to reality. It is
possible that it will not generalize properly. One way to deal with this situation is to use a cascade of classifers, each
viewing the reality left after the previous culled out unlikely prospects. We could do this in effect by using our
existing ranking mechanism to make the initial rough cut, using the classifier only to re-rank the remainder.

Finally, "learning to rank" is a well-studied machine learning algorithm. What we describe above is a particular approach to
this problem: pointwise ranking. In it each thing ranked is assigned a measure and this measure is used to rank the things.
Other approaches are pairwise ranking and (the terminology escapes me) n-wise ranking. In the former case, you are in effect
training a classifier to classify a pair of things as ordered or mis-ordered. You can use this classifier then to sort all
the items, because each sorting step involves a pair. The latter considers an item to be ranked in the context of all other
items. It is not terribly difficult to convert our data for use in pairwise ranking, though it is not trivial. In generaly,
the greater the context available in ranking the more accurate the algorithm can be, though as always with machine learning
there is the problem of overfitting: if your model is too flexible it can find spurious patterns that work in its training
data but do not generalize to novel data. So the more powerful the model you attempt to train, the more data you need in order
to prevent overfitting. We most likely are not rich in training data, so we are probably confined to pointwise or pairwise
ranking. However, we might try pairwise ranking to see whether it improves our accuracy. One trick one can use to multiply
ones data is to convert a set of matches and mismatches into a set or pairs that is twice the product of the two, so 2 matches and
10 mismatches becomes 40 training pairs: 20 correctly ordered pairs and 20 misordered pairs.
