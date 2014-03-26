cdef extern from 'ql/default.hpp' namespace 'QuantLib::Protection':

    enum Side:
        Buyer
        Seller


cdef extern from 'ql/instruments/creditdefaultswap.hpp' namespace 'QuantLib':

    cdef cppclass CreditDefaultSwap(Instrument):
        CreditDefaultSwap(Side side,
                          Real notional,
                          Rate spread,
                          Schedule& schedule,
                          BusinessDayConvention paymentConvention,
                          DayCounter& dayCounter,
                          bool settlesAccrual, # = true,
                          bool paysAtDefaultTime, # = true,
                          Date& protectionStart #= Date(),
                          #const boost::shared_ptr<Claim>& =
                          #                        boost::shared_ptr<Claim>());
        )
        Rate fairUpfront()
        Rate fairSpread()
        Real couponLegBPS()
        Real upfrontBPS()
        Real couponLegNPV()
        Real defaultLegNPV()
        Real upfrontNPV()

