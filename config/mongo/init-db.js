for (let i = 1; i <= (parseInt(process.env.REPLICAS) || 1); i++) {
  let dbName = `${process.env.MONGO_INITDB_DATABASE}-${i}`;
  let kowloonDb = db.getSiblingDB(dbName);
  kowloonDb.createUser(
    {
      user: `${process.env.MONGO_USER}`,
      pwd: `${process.env.MONGO_PASSWORD}`,
      roles: [
        {
          role: "readWrite",
          db: dbName
        }
      ]
    }
  );
}
