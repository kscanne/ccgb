#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <db.h>

void
cleanup (DB * dbp, int ret)
{
  int t_ret;

  if ((t_ret = dbp->close (dbp, 0)) != 0 && ret == 0)
    ret = t_ret;
  exit (ret);
}

int
main (int argc, char* argv[])
{
  DB *dbp;
  DBT key, data;
  int ret,len;
  char token[65535];

  if (argc != 2)
  {
   fprintf(stderr, "Usage: ppfaigh dbfile\n");
   exit (1);
  }

  if ((ret = db_create (&dbp, NULL, 0)) != 0)
    {
      fprintf (stderr, "db_create: %s\n", db_strerror (ret));
      exit (1);
    }
  if ((ret =
       dbp->open (dbp, NULL, argv[1], NULL, DB_HASH, DB_RDONLY, 0)) != 0)
    {
      dbp->err (dbp, ret, "%s", argv[1]);
      cleanup (dbp, ret);
    }

  while (fgets (token, 65535, stdin) != NULL)
    {
      memset (&key, 0, sizeof (key));
      memset (&data, 0, sizeof (data));
      len=strlen(token);
      token[len-1]=0;
      key.size = len-1;
      key.data = malloc (key.size + 1);
      strcpy (key.data, token);
      if ((ret = dbp->get (dbp, NULL, &key, &data, 0)) == 0) {
         ((char*) data.data)[data.size]=0;
	 printf ("%s\n", (char *) data.data);
	  ;
	}
      else
	{
	  fprintf(stderr, "Could not find key %s\n", key.data);
	  dbp->err (dbp, ret, "DB->get");
	  cleanup (dbp, ret);
	}
      free (key.data);
 //     free (data.data);
    }

  cleanup (dbp, ret);
}
