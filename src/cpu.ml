open Core
open Types
open Unsigned

exception HaltInstruction of string
exception UnrecognizedOpcode of string

let unknown_opcode opcode pc =
  let msg = sprintf "unknown opcode 0x%02x at pc 0x%04x" opcode pc in
  raise (UnrecognizedOpcode msg)

let nop state =
  (Utils.increment_pc state 1), 4, "NOP"

let disable_interrupts state =
  (Utils.increment_pc state 1), 4, "DI"

let halt pc =
  let msg = sprintf "encountered halt instruction at pc 0x%04x" pc in
  raise (HaltInstruction msg)

let next_bytes rom_array pc = Array.slice rom_array (pc + 1) 0

let is_load high_byte =
  match high_byte with
  | _ when high_byte >= 0x4 && high_byte <= 0x7 -> true
  | _ -> false

let print_debug pc opcode ticks msg =
    printf "pc[0x%04x]=0x%02x, ticks=%4d, %s\n" pc opcode ticks msg

let decode opcode rom_array state debug =
  let pc = UInt16.to_int state.pc in
  let code_bytes = next_bytes rom_array pc in
  let%bitstring bits = {|opcode : 8|} in
  let state, ticks, log_msg =
    match%bitstring bits with
    (* NOP *)
    | {| 0x00 : 8 |} -> nop state
    (* DISABLE INTERRUPTS *)
    | {| 0xf3 : 8 |} -> disable_interrupts state
    (* HALT INSTRUCTION -- must be matched before load instructions *)
    | {| 0x76 : 8 |} -> halt pc
    (* UNCONDITIONAL JUMP IMM *)
    | {| 0xc3 : 8 |} -> Jump.uncond_imm code_bytes state
    (* LOAD INSTRUCTIONS *)
    | {| high_byte : 4; low_byte : 4 |} when is_load high_byte ->
        Memory.load_register high_byte low_byte state
    (* XOR REGISTER *)
    | {| 0xa : 4; low_byte : 4|} when low_byte >= 0x8 ->
        Alu.xor_register state low_byte
    (* UNKNOWN INSTRUCTION *)
    | {| _ |} -> unknown_opcode opcode pc
  in
  (* UPDATE TICK COUNT *)
  state.ticks <- (state.ticks + ticks);
  (* PRINT DEBUG INFO *)
  match debug with
  | true -> print_debug pc opcode state.ticks log_msg
  | false -> ()

let rec run_loop rom_array state debug =
  let index = UInt16.to_int state.pc in
  decode (rom_array.(index)) rom_array state debug;
  run_loop rom_array state debug

let emulate rom_array debug =
  run_loop rom_array init_game_state debug
