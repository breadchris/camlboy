open Core
open Types
open Flagx
open Unsigned

let format_operation op0 op1 result operation =
  sprintf "0x%02x = 0x%02x %s 0x%02x"
    (UInt8.to_int op0) (UInt8.to_int op1) operation (UInt8.to_int result)

let update_zero_flag result state =
  clear_all_flags state;
  set_flag_value Zero (result = UInt8.zero) state

let do_reg_op state source operation =
  let op0 = Utils.get_register state A  in
  let op1 = Utils.get_register state source in
  let result = operation op0 op1 in
  Utils.set_register state A result;
  4, (format_operation op0 op1 result "XOR")

let xor_register state low =
  let operation = UInt8.logxor in
  let source_reg = register_array.(low - 0x8) in
  let tick, result_msg = match source_reg with
  | HL -> raise (NotImplemented "XOR from memory is not yet implemented")
  | Reg source -> do_reg_op state source operation
  in
  let msg = (sprintf "XOR ") ^ (reg_to_str source_reg) ^ " " ^ result_msg in
  (Utils.increment_pc state 1), tick, msg

let decrement state reg =
  let result = (UInt8.pred (Utils.get_register state reg)) in
  update_zero_flag result state;
  Utils.set_register state reg result;
  4

let dec_register state high low =
  let reg = register_array.(Utils.vertical_index high low) in
  let tick = match reg with
  | HL -> raise (NotImplemented "DEC HL is not yet implemented")
  | Reg register -> decrement state register
  in
  (Utils.increment_pc state 1), tick, (sprintf "DEC %s" (reg_to_str reg))
