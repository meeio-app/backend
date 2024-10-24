<?php

declare(strict_types=1);

namespace App\Enum\CountCriteria;

use App\Enum\EnumUtility;

enum SessionCountCriteria: string
{
    use EnumUtility;

    case ALL = 'all';
}
