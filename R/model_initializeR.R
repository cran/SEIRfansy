
model_initializeR <- function(data=NULL, data_init, init_pars, model = "Multinomial", period_start,
                  alpha_p = 0.5, alpha_u = 0.7, beta_1 = 0.6, beta_2 = 0.7, delta_1 = 0.3, delta_2 = 0.7,
                  lambda = 1 / (66.26 * 365), mu = 1 / (66.26 * 365), D_d = 17.8, De = 5.2,
                  Dr = 17.8, f = 0.15, mCFR = NULL, init.exposed.ratio = 3, init.confirmed.ratio = 0.15,
                  auto.initialize = TRUE,opt_num=100, override = FALSE, ... ){
  if(data_init[1]==0){
    stop("Please enter a non-zero value for the initial number of  total confirmed cases. A suggestion is replace 0 by 1 ")
  }
  if(!is.null(data)){
    if(model=="Multinomial"){
      if(! all(c("Confirmed", "Recovered", "Deceased" ) %in% colnames(data))){
        stop("Data does not contain required columns")
      }
      obsP = data$Confirmed
      obsR = data$Recovered
      obsD = data$Deceased
    }
    else if(model=="Poisson"||model=="Binomial"){
      if(! all(c("Confirmed") %in% colnames(data))){
        stop("Data does not contain required columns")
      }
      if(all(c("Confirmed", "Recovered", "Deceased" ) %in% colnames(data))){
        if(is.null(mCFR)) mCFR = tail(cumsum(obsD) / cumsum(obsD+obsR),1)
      }
      else if(is.null(mCFR)){
        stop("Please input the value of the mCFR. ")
      }
      obsP=data$Confirmed
    }

  if(is.null(mCFR)) mCFR = tail(cumsum(obsD) / cumsum(obsD+obsR),1)
  }
  else{
    if(is.null(mCFR)){
      stop("Please give the data or input the value of the mCFR ")
    }
  }

  mu_c = mCFR/D_d
  Dr = 17.8/(1-mCFR)

  ## Fixed parameters

  fix_pars = c(alpha_p = alpha_p, alpha_u = alpha_u, beta_1 = beta_1, beta_2 = beta_2, delta_1 = delta_1,
               delta_2 = delta_2, lambda = lambda, mu = mu, mu_c = mu_c, De = 5.2, Dr = Dr, f = f, N = N)

  ## Initializing parameters

  ## Initial states

  #initial number of ascertained cases
  P0  = data_init[1] - data_init[2] - data_init[3]
  #initial number of ascertained recoveries
  RR0 = data_init[2]
  #initial number of ascertained deaths
  DR0 = data_init[3]
  #initi number of false negatives
  F0 = round(f/(1-f) * P0)
  #initial number of unascertained infectious cases
  U0 =round( (P0 + F0) * (1-init.confirmed.ratio)/init.confirmed.ratio)
  #initial number of ascertained recoveries
  RR0 = data_init[2]
  #initial number of unascertained recoveries
  RU0 = round(((1-init.confirmed.ratio)/init.confirmed.ratio + f/(1-f)) * RR0)
  #initial number of ascertained deaths
  DR0 = data_init[3]
  #initial number of unascertained deaths
  DU0 = round(((1-init.confirmed.ratio)/init.confirmed.ratio + f/(1-f)) * DR0)
  #initial number of latent cases, De=5.3
  E0 = init.exposed.ratio*(U0 + P0 + F0)
  #initial number of susceptible individuals
  S0 = N - (E0 + U0 + P0 + F0 + RU0 + RR0 + DU0 + DR0)
  # initial states c(S = S0, E = E0, U = U0, P = P0, Fa = F0, RU = RU0, RR = RR0, DU = DU0, DR = DR0)
  yinit = c("S" = S0, "E" = E0, "U" = U0, "P" = P0, "Fa" = F0, "RU" = RU0, "RR" = RR0, "DU" = DU0, "DR" = DR0)

  if(period_start[1] != 1){
    period_start = c(1, period_start)
  }

  n_period=length(period_start)
  if(auto.initialize){
    init_pars = par_initializeR(data = data, data_init = data_init, init_pars = init_pars, fix_pars = fix_pars,
                                opt_num = opt_num,period_start=period_start,init_state_num = yinit, model = model,
                                ...)[3:(2*n_period+2)]
    message(" ")
    message("MLE estimates : ")
    message("beta = (", paste0(round(init_pars[1:n_period],2), collapse = ", "), ")")
    message("r = (", paste0(round(init_pars[n_period + 1:n_period],3), collapse = ", "), ")")
    message(" ")
  }
  else{
    if(is.null(init_pars) && !override){
      stop("Please enter the initial Parameters")
    }
  }

  if(length(period_start) != length(init_pars)/2 && !override)
    stop("Number of periods is not equal to number of initial parameters")


  return(list("init_pars" = init_pars, "fix_pars" = fix_pars, "init_state_num" = yinit, "period_start" = period_start))

}
