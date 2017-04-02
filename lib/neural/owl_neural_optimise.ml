(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)

open Owl_algodiff_ad


module Learning_Rate = struct

  type typ =
    | Const     of float
    | Decay     of float * float
    | Exp_decay of float * float

end


module Batch = struct

  type typ =
    | Fullbatch
    | Minibatch of int
    | Stochastic

  let run typ x y = match typ with
    | Fullbatch   -> x, y
    | Minibatch n -> Owl_dataset.draw_samples x y n
    | Stochastic  -> Owl_dataset.draw_samples x y 1

end


module Loss = struct

  type typ =
    | L1norm
    | L2norm
    | Quadratic
    | Cross_entropy

  let run typ y y' = match typ with
    | L1norm        -> Maths.(l1norm (y - y'))
    | L2norm        -> Maths.(l2norm (y - y'))
    | Quadratic     -> Maths.(l2norm_sqr (y - y'))
    | Cross_entropy -> Maths.(cross_entropy y y')

  let to_string = function
    | L1norm        -> "l1norm"
    | L2norm        -> "l2norm"
    | Quadratic     -> "quadratic"
    | Cross_entropy -> "cross_entropy"

end


module Gradient = struct

  type typ =
    | GD
    | Newton

end


module Regularisation = struct

  type typ =
    | L1norm of float
    | L2norm of float
    | NoReg

end


module Params = struct

  type typ = {
    mutable epochs          : int;
    mutable gradient        : Gradient.typ;
    mutable learning_rate   : Learning_Rate.typ;
    mutable loss            : Loss.typ;
    mutable batch           : Batch.typ;
  }

  let default () = None

end


let train (params : Params.typ) x y f update =
  let batch = Batch.run params.batch in
  let loss_fun = Loss.run params.loss in
  for i = 1 to params.epochs do
    let xt, yt = batch x y in
    ()
  done


let cross_entropy_loss y y' = Maths.(cross_entropy y y' / (F (Mat.row_num y |> float_of_int)))

let gd v g = Maths.(v - F 0.01 * g)

let train0 x y f update =
  for i = 1 to 1000 do
    let xt, yt = Owl_dataset.draw_samples x y 100 in
    let xt, yt = Mat xt, Mat yt in
    let loss = f (cross_entropy_loss yt) xt in
    update gd;
    loss |> unpack_flt |> Printf.printf "#%i : loss = %g\n" i |> flush_all;
  done
