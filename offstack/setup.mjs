// Off-stack database bootstrap, wired in via abap_transpile.json -> "setup".
// Connects an in-memory SQLite database as the DEFAULT connection, creates the
// DDIC tables the transpiler discovered and registers the Application Log objects
// of this repository (src/*.aplo.json) in BALOBJ / BALSUB. open-abap-bal validates
// the object and subobject of a log header against these two tables, so without
// them every name would be accepted and GIVEN_UNKNOWN_OBJECT_RAISES could not fail.
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";
import * as fs from "node:fs";
import * as path from "node:path";
import {fileURLToPath} from "node:url";

const sourceFolder = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "src");

export async function setup(abap, schemas, insert) {
  const db = new SQLiteDatabaseClient();
  abap.context.databaseConnections["DEFAULT"] = db;
  await db.connect();
  await db.execute(schemas.sqlite);
  await db.execute(insert);

  for (const file of fs.readdirSync(sourceFolder)) {
    if (!file.endsWith(".aplo.json")) {
      continue;
    }
    const object = file.split(".")[0].toUpperCase();
    const definition = JSON.parse(fs.readFileSync(path.join(sourceFolder, file), "utf8"));
    await db.execute(`INSERT INTO balobj (object) VALUES ('${object}');`);
    for (const subobject of definition.subobjects ?? []) {
      await db.execute(`INSERT INTO balsub (object, subobject) VALUES ('${object}', '${subobject.name.toUpperCase()}');`);
    }
  }
}
