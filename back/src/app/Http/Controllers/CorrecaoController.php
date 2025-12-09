<?php

namespace App\Http\Controllers;

use App\Lib\Dicionarios\Status;
use App\Models\Correcao;
use App\Models\Submissao;

class CorrecaoController extends Controller
{
    public function buscaPorSubmissao(Submissao $submissao)
    {
        $correcoes = Correcao::where('submissao_id', '=', $submissao->id)
            ->select(
                'correcao.id',
                'token',
                'caso_teste_id',
                'submissao_id',
                'status_correcao_id',
                'stdout',
                'stderr',
                'compile_output',
                'message'
            )
            ->get();

        $correcoes->transform(function ($correcao) {
            $statusInfo = Status::get($correcao->status_correcao_id);
            $correcao->status = $statusInfo['nome'] ?? 'Desconhecido';
            $correcao->makeHidden(['token', 'status_correcao_id']);
            return $correcao;
        });

        return response()->json($correcoes);
    }
}
