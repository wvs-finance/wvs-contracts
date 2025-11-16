# Theory

# Implementations

- need to be collaterized on $X$

    - swapable to $oX$
- has a redemption token $rX$
- has a option token $oX$
```
                             /--> (rX/x) ----mint: rX (X) --> 
user ---deposit(X)--> AMM --
                             \--> (oX/x)-----mint: oX (X) -->
   ----------------ox----------------
  |  - underlying         (X)             |          
  |  - consideration      (Y)             |
  |  - strike           (P_{Y/X}_T) = Y/X |              
  |  - expiration           T             |
  |  - isPut                              |
  | ______________________________________
```
- __underlying:__: user has the right to purchase
- __consideration:__: payment method for the underlying purchase
- __expiration:___: last date the option can be excercised
- __strike__: price for excersicing the option 

## Option Token ($oX$)
- represents the long position of the __option holder__ 

```
---------------ox----------

- [rx.balance(msg.sender) > 0 ^ IoX(oX).expiration > block.timestamp]IoX(oX).exercise()
    - swap(Y/X, P_{Y/X})
```

## Redemption Token ($rX$)

- represents the SHORT position of the __option writer__
- locks underlying collateral (deposits)

## Option Writer (seller)

- LP position represents a perpetual call covered option on the quote token.

 
- The LP is the SELLER
 
- obligated to SELL the underlying collateral $X$ when __option owner__ calls `option.exercise`

- can redeem consideration $Y$ prior to expiration
- can redeem collateral $X$ post-expiration


## Option Owner (buyer)

- entitled to BUY the underlying $X$ when calling `option.exercise`


## Riddles

- In the future, there may be a way to automatically determine if a pair is considered a Put
 or Call, but a puzzle to the reader...

- burn expired tokens so they aren’t used for scams.

----------------
- LP is interested on forecasting volatility $\hat{\sigma}$ to stay always on the optimal tick range

- If current price is $\big (P_{Y/X} )_0$

$$
\begin{align*}
    \mathbb{P} \bigg [ (P_{Y/X} )_0 \in \big [P_l, P_u \big] \bigg | (P_{Y/X} )_T \in  \big [P_l, P_u \big] \bigg ] &= \
    - \text{Erf} \bigg (\frac{\ln \big (\sqrt{\frac{P_b}{P_a}}\big)}{\sigma \sqrt{2T}}\bigg)
\end{align*}
$$

- The implied volatility is the variance of the strike prices of options for a certain maturity time $T$


$$
\begin{align*}
    \hat{\sigma} = 2 \cdot \phi \sqrt{\frac{\mathrm{V}\left([p_l, p_u]\right)}{r_x \cdot r_y}}
\end{align*}
$$

