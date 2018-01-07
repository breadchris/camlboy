open Core
open Types
open Unsigned


let pack_ints_to_u16 high low =
  let word = UInt16.of_int high in
  UInt16.logor (UInt16.shift_left word 8) (UInt16.of_int low)

let increment_pc state increment =
  state.pc <- UInt16.add state.pc (UInt16.of_int increment);
  state

let get_register state reg =
  match reg with
  | A -> state.registers.a
  | B -> state.registers.b
  | C -> state.registers.c
  | D -> state.registers.d
  | E -> state.registers.e
  | H -> state.registers.h
  | L -> state.registers.l

let set_register state reg value =
  match reg with
  | A -> state.registers.a <- value
  | B -> state.registers.b <- value
  | C -> state.registers.c <- value
  | D -> state.registers.d <- value
  | E -> state.registers.e <- value
  | H -> state.registers.h <- value
  | L -> state.registers.l <- value

let get_hl state =
  let high = (UInt8.to_int (get_register state H)) in
  let low = (UInt8.to_int (get_register state L)) in
  pack_ints_to_u16 high low
