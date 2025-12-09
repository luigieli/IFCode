<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Correcao extends Model
{

    protected $table = 'correcao';
    protected $fillable = [
        'id',
        'token',
        'status_correcao_id',
        'submissao_id',
        'caso_teste_id',
        'stdout',
        'stderr',
        'compile_output',
        'message'
    ];
}
