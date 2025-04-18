// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtlul_interconnect_tb__pch.h"

//============================================================
// Constructors

Vtlul_interconnect_tb::Vtlul_interconnect_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtlul_interconnect_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtlul_interconnect_tb::Vtlul_interconnect_tb(const char* _vcname__)
    : Vtlul_interconnect_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtlul_interconnect_tb::~Vtlul_interconnect_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtlul_interconnect_tb___024root___eval_debug_assertions(Vtlul_interconnect_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vtlul_interconnect_tb___024root___eval_static(Vtlul_interconnect_tb___024root* vlSelf);
void Vtlul_interconnect_tb___024root___eval_initial(Vtlul_interconnect_tb___024root* vlSelf);
void Vtlul_interconnect_tb___024root___eval_settle(Vtlul_interconnect_tb___024root* vlSelf);
void Vtlul_interconnect_tb___024root___eval(Vtlul_interconnect_tb___024root* vlSelf);

void Vtlul_interconnect_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtlul_interconnect_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtlul_interconnect_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtlul_interconnect_tb___024root___eval_static(&(vlSymsp->TOP));
        Vtlul_interconnect_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vtlul_interconnect_tb___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtlul_interconnect_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtlul_interconnect_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vtlul_interconnect_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtlul_interconnect_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtlul_interconnect_tb___024root___eval_final(Vtlul_interconnect_tb___024root* vlSelf);

VL_ATTR_COLD void Vtlul_interconnect_tb::final() {
    Vtlul_interconnect_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtlul_interconnect_tb::hierName() const { return vlSymsp->name(); }
const char* Vtlul_interconnect_tb::modelName() const { return "Vtlul_interconnect_tb"; }
unsigned Vtlul_interconnect_tb::threads() const { return 1; }
void Vtlul_interconnect_tb::prepareClone() const { contextp()->prepareClone(); }
void Vtlul_interconnect_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vtlul_interconnect_tb::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vtlul_interconnect_tb::trace()' called on model that was Verilated without --trace option");
}
