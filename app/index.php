<?php
$db_host = getenv('DB_HOST') ?: 'mariadb';
$db_user = getenv('DB_USER') ?: 'appuser';
$db_pass = getenv('DB_PASS') ?: 'apppass';
$db_name = getenv('DB_NAME') ?: 'hellodb';

$status = 'Disconnected';
$error = '';
$count = 0;

try {
    $pdo = new PDO(
        "mysql:host={$db_host};dbname={$db_name}",
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $pdo->exec("CREATE TABLE IF NOT EXISTS visits (
        id INT AUTO_INCREMENT PRIMARY KEY,
        visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    $pdo->exec("INSERT INTO visits (visited_at) VALUES (NOW())");

    $count = $pdo->query("SELECT COUNT(*) FROM visits")->fetchColumn();
    $status = 'Connected';

} catch (PDOException $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hello LAMP on RHEL</title>
    <style>
        body {
            font-family: sans-serif;
            max-width: 600px;
            margin: 4em auto;
        }
        .ok { color: green; }
        .fail { color: red; }
    </style>
</head>
<body>
    <h1>Hello World - LAMP on RHEL (Hardened Images)</h1>
    <ul>
        <li>PHP version: <?= phpversion() ?></li>
        <li>
            MariaDB status:
            <span class="<?= $status === 'Connected' ? 'ok' : 'fail' ?>">
                <?= htmlspecialchars($status) ?>
            </span>
        </li>

        <?php if ($status === 'Connected'): ?>
            <li>Total visits: <?= (int)$count ?></li>
        <?php endif; ?>

        <?php if ($error): ?>
            <li class="fail">Error: <?= htmlspecialchars($error) ?></li>
        <?php endif; ?>
    </ul>
</body>
</html>
