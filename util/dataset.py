import os
import sys
from typing import Any, Tuple

import numpy as np

import torch
from torch.utils.data import Dataset
from torchvision import transforms

import util.transformations as transformations
import util.augmentations as augmentations


class SignalDataset(Dataset):
    """Fast EEGDataset (fetching prepared data and labels from files)"""
    def __init__(self, data_path, labels_path, transform=False, augment=False, args=None) -> None:
        """load data and labels from files"""
        self.transform = transform
        self.augment = augment
        
        self.args = args

        self.data = torch.load(data_path, map_location=torch.device('cpu')) # load to ram
        self.labels = torch.load(labels_path, map_location=torch.device('cpu')) # load to ram

    def __len__(self) -> int:
        """return the number of samples in the dataset"""
        return len(self.labels)

    def __getitem__(self, idx) -> Tuple[Any, Any]:
        """return a sample from the dataset at index idx"""

        data, label = self.data[idx], self.labels[idx]
        if self.args.input_size[0] == 1:
            data = data.unsqueeze(dim=0)

        data = data[:, :self.args.input_electrodes, :]
        
        if self.transform == True:
            transform = augmentations.CropResizing(fixed_crop_len=self.args.input_size[-1], start_idx=0, resize=False)
            data = transform(data)

        if self.augment == True:
            # lower_bnd = self.args.crop_lbd * self.args.input_size[-1] / data.shape[-1]
            # upper_bnd = 1.00 * self.args.input_size[-1] / data.shape[-1]
            augment = transforms.Compose([augmentations.Jitter(sigma=self.args.jitter_sigma),
                                          augmentations.Rescaling(sigma=self.args.rescaling_sigma),
                                          augmentations.FTSurrogate(phase_noise_magnitude=self.args.ft_surr_phase_noise, prob=0.5),
                                          augmentations.CropResizing(fixed_crop_len=self.args.input_size[-1], resize=False),
                                          #augmentations.TimeFlip(prob=0.33),
                                          #augmentations.SignFlip(prob=0.33)
                                          ])
            data = augment(data)
        
        if self.args.nb_classes == 1:
            return data, torch.tensor([label], dtype=torch.float32)
        else:
            return data, label