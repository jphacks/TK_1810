import numpy as np

# calculate mean score for AVA dataset
def mean_score(scores):
    si = np.arange(1, 11, 1)
    mean = np.sum(scores * si)
    return mean

# calculate standard deviation of scores for AVA dataset
def std_score(scores):
    si = np.arange(1, 11, 1)
    mean = mean_score(scores)
    std = np.sqrt(np.sum(((si - mean) ** 2) * scores))
    return std

# customize
def mean_score_batch(scores):
    si = np.arange(1, 11, 1)
    mean_array = scores * si
    return np.sum(mean_array, axis=1)

def std_score_batch(scores):
    si = np.full((scores.shape[0], 10), np.arange(1, 11, 1)).transpose(1, 0)
    mean = mean_score_batch(scores)
    diff = si - mean
    power = np.power(diff, 2).transpose(1, 0)
    return np.sqrt(np.sum(power * scores, axis=1))