# SpiROSE LCD DISPLAY

## Description

We use the STM32f746g-DISCOVERY board as the fixed base controller. It has an LCD capacitive touchscreen to allow a smooth interaction between a user and SpiROSE. The µgfx library is used in coordination with ST's HAL Driver.

## Use

This project contains a submodule. To be able to use the project properly, proceed as follows :

```
git submodule init
git submodule update
```

To build the project, use

```
make
```

